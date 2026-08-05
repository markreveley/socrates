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

  alias Socrates.{Journal, Loadout, Render, Sid, Statement}

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
      ["render" | rest] -> with_store(rest, &cmd_render/2)
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
      render [selector]         the bracket-notation document
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

    {errors, warnings} = Statement.lint(s)
    {origin, origin_errors} = hash_origin(s.origin, s.type)
    {dep_sids, dep_errors} = resolve_deps(ctx.fold, Keyword.get_values(opts, :dep), s.type)

    case errors ++ origin_errors ++ dep_errors do
      [] -> {:ok, %{s | origin: origin, deps: dep_sids}, warnings}
      errors -> {:error, errors}
    end
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

  defp hash_origin(nil, _type), do: {nil, []}

  defp hash_origin(%{kind: "file", locator: path} = origin, type) do
    case File.read(path) do
      {:ok, bytes} ->
        {%{origin | sha256: sha256(bytes)}, []}

      {:error, _} ->
        {origin, [%{code: "E_REF_NO_ORIGIN", subject: type, detail: "file #{path} not found"}]}
    end
  end

  defp hash_origin(origin, _type), do: {origin, []}

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

  # Selectors: nothing (whole graph) is all M1 needs; id / id+deps / id+rdeps /
  # @exchange land at M2 with the graph.
  defp select(fold, nil), do: Enum.map(fold.order, &fold.statements[&1])
  defp select(_fold, selector), do: abort("unknown selector: #{selector}", 2)

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

    if length(args) > max_args, do: abort("unexpected argument: #{Enum.at(args, max_args)}", 2)
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
