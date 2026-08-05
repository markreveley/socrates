defmodule Socrates.CLI do
  @moduledoc """
  escript `main/1`: dispatch, exit codes, stderr footers.

  Output discipline (D6): stdout carries only the artifact; the boundary
  footer, progress, gate errors/warnings, and confirmations go to stderr;
  status goes in exit codes (`0` ok · `1` gate/lint-rejected · `2` usage or
  environment error · `3` verify mismatch). Every command ends with a
  boundary footer on stderr. Store discovery is `./.socrates` in the cwd
  only — no ancestor walking.
  """

  alias Socrates.{Gate, Graph, Journal, Loadout, Render, Sid, Statement}

  @code_order ~w(E_ID_FORM E_DUP_ID E_DANGLING_DEP E_CYCLE E_TERM_UNDEF E_DEF_NO_SCOPE E_REF_NO_ORIGIN W_DEF_ATOMICITY)

  @store ".socrates"

  def main(argv) do
    System.halt(run(argv))
  end

  @doc "Run one invocation; prints directly, returns the exit code."
  def run(argv) do
    Process.put(:socrates_footer, :deterministic)

    code =
      try do
        dispatch(argv)
      catch
        {:abort, code} -> code
      end

    IO.write(:stderr, footer_line() <> "\n")
    code
  end

  defp dispatch(argv) do
    case argv do
      ["init" | rest] -> cmd_init(rest)
      ["add" | rest] -> with_store(rest, &cmd_add/2)
      ["show" | rest] -> with_store(rest, &cmd_show/2)
      ["deps" | rest] -> with_store(rest, &cmd_deps(&1, &2, :deps))
      ["rdeps" | rest] -> with_store(rest, &cmd_deps(&1, &2, :rdeps))
      ["graph" | rest] -> with_store(rest, &cmd_graph/2)
      ["render" | rest] -> with_store(rest, &cmd_render/2)
      ["ratify" | rest] -> with_store(rest, &cmd_transition(&1, &2, "ratified"))
      ["reject" | rest] -> with_store(rest, &cmd_transition(&1, &2, "rejected"))
      ["verify" | rest] -> with_store(rest, &cmd_verify/2)
      ["log" | rest] -> with_store(rest, &cmd_log/2)
      [] -> abort(usage_text(), 2)
      [cmd | _] -> abort("unknown command: #{cmd}", 2)
    end
  end

  defp usage_text do
    """
    usage: socrates <command> [args]
      init                      create ./.socrates
      add --type <t> [flags]    author one statement (body via --body or stdin)
      show <id>                 full record for one statement
      deps <id> [--all]         direct (or transitive) dependencies
      rdeps <id> [--all]        direct (or transitive) dependents
      graph [selector]          indented dependency tree
      render [selector] [--ascii]  the bracket-notation document
      ratify <id>...            ratify proposed statements
      reject <id>... [--note <text>]  reject proposed statements
      verify                    re-hash archived sources and ref origins
      log [--limit <n>]         journal events, newest last\
    """
  end

  ## Store plumbing

  defp with_store(rest, f) do
    unless File.dir?(@store) do
      abort("no #{@store} here (run: socrates init)", 2)
    end

    fold = fold_or_abort()
    Journal.export_definitions(@store, fold)
    f.(rest, %{dir: @store, fold: fold})
  end

  defp fold_or_abort do
    Journal.fold(@store)
  rescue
    e in Journal.Error -> abort(Exception.message(e), 2)
  end

  defp refresh(ctx) do
    fold = fold_or_abort()
    Journal.export_definitions(ctx.dir, fold)
    %{ctx | fold: fold}
  end

  ## init

  defp cmd_init(rest) do
    parse!(rest, [], 0)

    if File.exists?(@store) do
      abort("#{@store} already exists", 2)
    end

    File.mkdir_p!(Path.join(@store, "sources"))
    File.write!(Path.join(@store, "journal.jsonl"), "")
    Journal.append(@store, %{event: "exchange_opened", exchange: 1, ts: now()})
    Journal.export_definitions(@store, Journal.fold(@store))
    note("initialized #{@store}/")
    0
  end

  ## add

  @add_switches [
    type: :string,
    body: :string,
    dep: :keep,
    note: :keep,
    term: :string,
    scope: :string,
    origin: :string
  ]

  defp cmd_add(rest, ctx) do
    opts = parse!(rest, @add_switches, 0)
    build = statement_from_flags(opts, ctx)

    case build do
      {:error, errors} ->
        Enum.each(errors, &print_finding/1)
        1

      {:ok, s, warnings} ->
        Enum.each(warnings, &print_finding/1)
        s = finalize_operator(s, ctx, exchange: 1)
        Journal.append(ctx.dir, %{event: "statement_added", statement: s, ts: s.inserted_at})
        refresh(ctx)
        IO.write("#{s.display_id} #{s.sid}\n")
        0
    end
  end

  # Shared by add (and amend at M4): flags → linted statement, deps resolved
  # to sids against the fold (deps are sid-edges, D7). Usage-shaped problems
  # abort 2; content problems return {:error, findings} (exit 1, nothing
  # journaled).
  defp statement_from_flags(opts, ctx, fixed_type \\ nil) do
    type = fixed_type || opts[:type] || abort("--type required", 2)

    unless type in Loadout.types() do
      abort("unknown type: #{type}", 2)
    end

    if opts[:term] && type != "def", do: abort("--term is def-only", 2)
    if opts[:scope] && type != "def", do: abort("--scope is def-only", 2)
    if opts[:origin] && type != "ref", do: abort("--origin is ref-only", 2)
    if type == "def" && !opts[:term], do: abort("def requires --term", 2)

    body = body_from(opts)

    s = %Statement{
      type: type,
      body: body,
      term: opts[:term],
      scope: opts[:scope],
      origin: parse_origin(opts[:origin]),
      notes: Keyword.get_values(opts, :note)
    }

    {dep_sids, dep_errors} = resolve_deps(ctx.fold, Keyword.get_values(opts, :dep), s.type)

    case Gate.check_operator(s, ctx.fold) do
      {:ok, s, warnings} when dep_errors == [] ->
        {:ok, %{s | deps: dep_sids}, warnings}

      {:ok, _s, _warnings} ->
        {:error, dep_errors}

      {:error, errors, _warnings} ->
        {:error, sort_findings(errors ++ dep_errors)}
    end
  end

  defp sort_findings(findings) do
    Enum.sort_by(findings, fn %{code: code} -> Enum.find_index(@code_order, &(&1 == code)) end)
  end

  defp body_from(opts) do
    body =
      case opts[:body] do
        nil ->
          case IO.read(:stdio, :eof) do
            :eof -> ""
            {:error, _} -> ""
            data -> String.replace_suffix(data, "\n", "")
          end

        body ->
          body
      end

    if String.trim(body) == "", do: abort("body required (--body or stdin)", 2)
    body
  end

  defp parse_origin(nil), do: nil

  defp parse_origin(arg) do
    case String.split(arg, ":", parts: 2) do
      [kind, locator] when locator != "" -> %{kind: kind, locator: locator, sha256: nil}
      _ -> abort("--origin takes <kind>:<locator>", 2)
    end
  end

  defp resolve_deps(fold, dep_args, subject) do
    {sids, errors} =
      Enum.reduce(dep_args, {[], []}, fn arg, {sids, errors} ->
        case resolve(fold, arg) do
          nil ->
            {sids,
             [
               %{code: "E_DANGLING_DEP", subject: subject, detail: "dep #{arg} not found"}
               | errors
             ]}

          %{state: state, display_id: id} when state in ["rejected", "superseded"] ->
            {sids,
             [%{code: "E_DANGLING_DEP", subject: subject, detail: "dep #{id} #{state}"} | errors]}

          s ->
            {[s.sid | sids], errors}
        end
      end)

    {Enum.reverse(sids), Enum.reverse(errors)}
  end

  defp finalize_operator(s, ctx, exchange: exchange) do
    ts = now()

    %{
      s
      | sid: Sid.generate(),
        display_id: s.display_id || "#{s.type}_#{Journal.next_index(ctx.fold, s.type)}",
        exchange: exchange,
        seq: Enum.count(ctx.fold.order, &(ctx.fold.statements[&1].exchange == exchange)) + 1,
        state: "ratified",
        author: "operator",
        inserted_at: ts
    }
  end

  ## show

  defp cmd_show(rest, ctx) do
    arg =
      case args_only(rest, 1) do
        {_, [arg]} -> arg
        {_, []} -> abort("usage: socrates show <id>", 2)
      end

    s = resolve(ctx.fold, arg) || abort("unknown id: #{arg}", 2)

    IO.write(Render.line(s, display_fun(ctx.fold), render_opts()) <> "\n")

    deps =
      case s.deps do
        [] -> "-"
        sids -> Enum.map_join(sids, ", ", display_fun(ctx.fold))
      end

    chain_sids = MapSet.new(ctx.fold.chains[s.display_id] || [s.sid])

    rdeps_count =
      Enum.count(ctx.fold.order, fn sid ->
        Enum.any?(ctx.fold.statements[sid].deps, &MapSet.member?(chain_sids, &1))
      end)

    provenance =
      case s.provenance do
        nil ->
          "-"

        %{calls: calls} ->
          %{model: m, request_id: r, usage: u} = List.last(calls)
          "#{m} · #{r} · #{u.input_tokens} in / #{u.output_tokens} out"
      end

    IO.write("""
    sid: #{s.sid}
    exchange: #{s.exchange}
    state: #{s.state}
    author: #{s.author}
    deps: #{deps}
    rdeps: #{rdeps_count}
    provenance: #{provenance}
    revises: #{s.revises || "-"}
    """)

    0
  end

  ## render

  defp cmd_render(rest, ctx) do
    {opts, args} = args_only(rest, 1, ascii: :boolean)
    statements = select(ctx.fold, List.first(args))
    visible = Enum.filter(statements, &(&1.state in ["proposed", "ratified"]))

    IO.write(
      Render.document(
        visible,
        display_fun(ctx.fold),
        render_opts() ++ [ascii: opts[:ascii] || false]
      )
    )

    0
  end

  # Selectors: nothing (the whole graph) · <id> · <id>+deps · <id>+rdeps ·
  # @<exchange>. Nothing else in v0.
  defp select(fold, nil), do: Enum.map(fold.order, &fold.statements[&1])

  defp select(fold, "@" <> exchange) do
    case Integer.parse(exchange) do
      {n, ""} -> fold.order |> Enum.map(&fold.statements[&1]) |> Enum.filter(&(&1.exchange == n))
      _ -> abort("unknown selector: @#{exchange}", 2)
    end
  end

  defp select(fold, selector) do
    case String.split(selector, "+") do
      [id] ->
        [resolve(fold, id) || abort("unknown id: #{id}", 2)]

      [id, closure] when closure in ["deps", "rdeps"] ->
        s = resolve(fold, id) || abort("unknown id: #{id}", 2)

        neighbors =
          case closure do
            "deps" -> dep_neighbors(fold)
            "rdeps" -> rdep_neighbors(fold)
          end

        [s | s.display_id |> Graph.reach(neighbors) |> Enum.map(&Journal.head(fold, &1))]

      _ ->
        abort("unknown selector: #{selector}", 2)
    end
  end

  # Neighbor functions over display ids, traversing the live graph.
  defp dep_neighbors(fold) do
    fn display_id ->
      case Journal.head(fold, display_id) do
        %{state: state} = s when state in ["proposed", "ratified"] ->
          Enum.map(s.deps, display_fun(fold))

        _ ->
          []
      end
    end
  end

  defp rdep_neighbors(fold) do
    map = rdeps_map(fold)
    fn display_id -> Map.get(map, display_id, []) end
  end

  # display_id → [dependent display ids], live dependents, journal order.
  # Chain-aware: an edge to any sid of a chain counts as an edge to it.
  defp rdeps_map(fold) do
    for sid <- fold.order,
        s = fold.statements[sid],
        s.state in ["proposed", "ratified"],
        dep_sid <- s.deps,
        reduce: %{} do
      acc ->
        target = fold.statements[dep_sid].display_id
        Map.update(acc, target, [s.display_id], &(&1 ++ [s.display_id]))
    end
  end

  ## deps / rdeps

  defp cmd_deps(rest, ctx, direction) do
    {opts, args} = args_only(rest, 1, all: :boolean)

    arg =
      case args do
        [arg] -> arg
        [] -> abort("usage: socrates #{direction} <id> [--all]", 2)
      end

    s = resolve(ctx.fold, arg) || abort("unknown id: #{arg}", 2)

    ids =
      case {direction, opts[:all]} do
        {:deps, true} ->
          Graph.reach(s.display_id, dep_neighbors(ctx.fold))

        {:deps, _} ->
          Enum.map(s.deps, display_fun(ctx.fold))

        {:rdeps, true} ->
          Graph.reach(s.display_id, rdep_neighbors(ctx.fold))

        {:rdeps, _} ->
          Map.get(rdeps_map(ctx.fold), s.display_id, [])
      end

    Enum.each(ids, &IO.write(&1 <> "\n"))
    0
  end

  ## graph

  defp cmd_graph(rest, ctx) do
    {_opts, args} = args_only(rest, 1)

    selection =
      ctx.fold |> select(List.first(args)) |> Enum.filter(&(&1.state in ["proposed", "ratified"]))

    keys = MapSet.new(selection, & &1.display_id)
    by_key = Map.new(selection, &{&1.display_id, &1})

    dependents =
      for s <- selection, dep_sid <- s.deps, reduce: MapSet.new() do
        acc -> MapSet.put(acc, ctx.fold.statements[dep_sid].display_id)
      end

    roots = Enum.reject(selection, &MapSet.member?(dependents, &1.display_id))
    roots = if roots == [] and selection != [], do: selection, else: roots

    Enum.each(roots, &print_tree(&1, 0, by_key, keys, ctx, MapSet.new()))
    0
  end

  defp print_tree(s, depth, by_key, keys, ctx, on_path) do
    indent = String.duplicate("  ", depth)
    IO.write(indent <> Render.line(s, display_fun(ctx.fold), render_opts()) <> "\n")

    unless MapSet.member?(on_path, s.display_id) do
      on_path = MapSet.put(on_path, s.display_id)

      for dep_sid <- s.deps,
          dep_id = ctx.fold.statements[dep_sid].display_id,
          MapSet.member?(keys, dep_id) do
        print_tree(by_key[dep_id], depth + 1, by_key, keys, ctx, on_path)
      end
    end
  end

  ## ratify / reject

  defp cmd_transition(rest, ctx, new_state) do
    switches = if new_state == "rejected", do: [note: :string], else: []
    {opts, args} = args_only(rest, :any, switches)
    if args == [], do: abort("usage: socrates #{verb(new_state)} <id>...", 2)

    statements =
      args
      |> Enum.map(fn arg -> resolve(ctx.fold, arg) || abort("unknown id: #{arg}", 2) end)
      |> Enum.uniq_by(& &1.sid)

    Enum.each(statements, fn s ->
      if s.state != "proposed" do
        abort("#{s.display_id} is #{s.state}, not proposed", 2)
      end
    end)

    Enum.each(statements, fn s ->
      Journal.append(ctx.dir, %{
        event: "state_changed",
        sid: s.sid,
        state: new_state,
        note: opts[:note],
        ts: now()
      })
    end)

    refresh(ctx)
    note("#{length(statements)} #{new_state}")
    0
  end

  defp verb("ratified"), do: "ratify"
  defp verb("rejected"), do: "reject"

  ## verify

  defp cmd_verify(rest, ctx) do
    args_only(rest, 0)
    {records, conflicts} = archive_records(ctx.fold)

    source_problems =
      conflicts ++
        Enum.flat_map(records, fn {path, sha} ->
          case File.read(Path.join(ctx.dir, path)) do
            {:ok, bytes} -> if sha256(bytes) == sha, do: [], else: ["MISMATCH #{ctx.dir}/#{path}"]
            {:error, _} -> ["MISSING #{ctx.dir}/#{path}"]
          end
        end)

    recorded = MapSet.new(records, fn {path, _} -> path end)

    unrecorded =
      ctx.dir
      |> Path.join("sources/**")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&Path.relative_to(&1, ctx.dir))
      |> Enum.reject(&MapSet.member?(recorded, &1))
      |> Enum.sort()
      |> Enum.map(&"UNRECORDED #{ctx.dir}/#{&1}")

    refs =
      ctx.fold.chains
      |> Enum.map(fn {_id, sids} -> ctx.fold.statements[List.last(sids)] end)
      |> Enum.filter(
        &(&1.type == "ref" and &1.state in ["proposed", "ratified"] and
            match?(%{kind: "file", sha256: sha} when is_binary(sha), &1.origin))
      )
      |> Enum.sort_by(& &1.display_id)

    origin_problems =
      Enum.flat_map(refs, fn ref ->
        case File.read(ref.origin.locator) do
          {:ok, bytes} ->
            if sha256(bytes) == ref.origin.sha256,
              do: [],
              else: ["MISMATCH #{ref.origin.locator}"]

          {:error, _} ->
            ["MISSING #{ref.origin.locator}"]
        end
      end)

    case source_problems ++ unrecorded ++ origin_problems do
      [] ->
        note("sources: #{length(records)} files ok · ref origins: #{length(refs)} checked")
        0

      problems ->
        Enum.each(problems, &note/1)
        3
    end
  end

  # Every archived file the journal records a digest for: exchange sources
  # (exchange_opened), response archives (provenance calls), rejected
  # artifacts (intake_rejected). Paths are store-relative. Conflicting
  # records for one path are reported as mismatches.
  defp archive_records(fold) do
    records =
      Enum.flat_map(fold.events, fn
        %{event: "exchange_opened", source: %{path: path, sha256: sha}} ->
          [{path, sha}]

        %{event: "statement_added", statement: %{provenance: %{calls: calls}, exchange: ex}} ->
          Enum.map(calls, &{"sources/#{ex}/response-#{&1.n}.json", &1.response_sha256})

        %{event: "intake_rejected", exchange: ex, calls: calls, rejected: rejected} ->
          Enum.map(calls, &{"sources/#{ex}/response-#{&1.n}.json", &1.response_sha256}) ++
            if(rejected, do: [{rejected.path, rejected.sha256}], else: [])

        _ ->
          []
      end)

    {deduped, conflicts} =
      Enum.reduce(records, {%{}, []}, fn {path, sha}, {seen, conflicts} ->
        case seen do
          %{^path => ^sha} -> {seen, conflicts}
          %{^path => _other} -> {seen, ["MISMATCH .socrates/#{path}" | conflicts]}
          _ -> {Map.put(seen, path, sha), conflicts}
        end
      end)

    {Enum.to_list(deduped), Enum.reverse(conflicts)}
  end

  ## log

  defp cmd_log(rest, ctx) do
    {opts, []} = args_only(rest, 0, limit: :integer)
    limit = opts[:limit] || 50

    ctx.fold.events
    |> Enum.take(-limit)
    |> Enum.each(&IO.write(event_line(&1) <> "\n"))

    0
  end

  defp event_line(%{event: "statement_added", statement: s, ts: ts}) do
    "#{ts} statement_added #{s.display_id} #{s.sid}" <>
      if s.revises, do: " revises #{s.revises}", else: ""
  end

  defp event_line(%{event: "state_changed", sid: sid, state: state, ts: ts}),
    do: "#{ts} state_changed #{sid} #{state}"

  defp event_line(%{event: "exchange_opened", exchange: n, ts: ts}),
    do: "#{ts} exchange_opened @#{n}"

  defp event_line(%{event: "intake_rejected", exchange: n, ts: ts}),
    do: "#{ts} intake_rejected @#{n}"

  ## Shared helpers

  defp resolve(fold, arg) do
    cond do
      Regex.match?(Loadout.id_pattern(), arg) -> Journal.head(fold, arg)
      Sid.valid?(arg) -> fold.statements[arg]
      true -> nil
    end
  end

  defp display_fun(fold), do: fn sid -> fold.statements[sid].display_id end

  defp render_opts do
    [ansi: IO.ANSI.enabled?()]
  end

  defp print_finding(%{code: code, subject: subject, detail: detail}) do
    IO.write(:stderr, "#{code} #{subject}: #{detail}\n")
  end

  defp note(msg), do: IO.write(:stderr, msg <> "\n")

  defp now, do: DateTime.utc_now(:second) |> DateTime.to_iso8601()

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp parse!(rest, switches, max_args) do
    {opts, args} = args_only(rest, max_args, switches)
    if args != [], do: abort("unexpected argument: #{hd(args)}", 2)
    opts
  end

  defp args_only(rest, max_args, switches \\ []) do
    {opts, args, invalid} = OptionParser.parse(rest, strict: switches)

    case invalid do
      [] -> :ok
      [{flag, _} | _] -> abort("unknown option: #{flag}", 2)
    end

    if max_args != :any and length(args) > max_args do
      abort("unexpected argument: #{Enum.at(args, max_args)}", 2)
    end

    {opts, args}
  end

  defp abort(msg, code) do
    IO.write(:stderr, msg <> "\n")
    throw({:abort, code})
  end

  defp footer_line do
    case Process.get(:socrates_footer) do
      {:inference, model, request_id, tin, tout} ->
        "[inference: #{model} · #{request_id} · #{tin} in / #{tout} out]"

      _ ->
        "[deterministic]"
    end
  end
end
