defmodule Socrates.Gate do
  @moduledoc """
  The check pipeline — structured errors and warnings, in gate-table order:

      E_ID_FORM · E_DUP_ID · E_DANGLING_DEP · E_CYCLE · E_TERM_UNDEF ·
      E_DEF_NO_SCOPE · E_REF_NO_ORIGIN · W_DEF_ATOMICITY (warning)

  Two entry points. `check_artifact/2` runs on every model proposal: subjects
  are the model's artifact-local display ids (the conversation the model can
  follow — D7), deps resolve against artifact-local ids ∪ live ratified
  :global defs only (loadout-v0 § dep scope). `check_operator/2` runs on
  human-authored statements (minus the repair loop): the operator sees the
  store, so terms resolve against any live def in it. Both hash file origins
  — measured, never trusted — and hand back the stamped statements.
  """

  alias Socrates.{Graph, Journal, Loadout, Statement}

  @doc """
  Gate one model artifact (statements carry `artifact_id` and artifact-local
  `deps`). Returns `{:ok, statements, warnings}` with origins hashed, or
  `{:error, errors, warnings}`.
  """
  def check_artifact(statements, fold) do
    global_defs = Journal.global_defs(fold)
    global_ids = MapSet.new(global_defs, & &1.display_id)
    local_ids = Enum.map(statements, & &1.artifact_id)

    id_form_errors =
      for s <- statements,
          not (Regex.match?(Loadout.id_pattern(), s.artifact_id || "") and
                 String.starts_with?(s.artifact_id, s.type <> "_")),
          do: finding("E_ID_FORM", s.artifact_id || s.type, "display id must be #{s.type}_<n>")

    dup_errors =
      (local_ids -- Enum.uniq(local_ids))
      |> Enum.uniq()
      |> Enum.map(&finding("E_DUP_ID", &1, "display id minted twice in the artifact"))
      |> Kernel.++(
        for s <- statements,
            MapSet.member?(global_ids, s.artifact_id),
            do: finding("E_DUP_ID", s.artifact_id, "collides with global #{s.artifact_id}")
      )

    resolvable = MapSet.union(MapSet.new(local_ids), global_ids)

    dangling_errors =
      for s <- statements,
          dep <- s.deps,
          not MapSet.member?(resolvable, dep),
          do: finding("E_DANGLING_DEP", s.artifact_id, "dep #{dep} not found")

    cycle_errors =
      case Graph.cycle(statements, & &1.deps, & &1.artifact_id) do
        nil -> []
        path -> [finding("E_CYCLE", hd(path), "dependency cycle: #{Enum.join(path, " -> ")}")]
      end

    terms_in_scope =
      MapSet.union(
        MapSet.new(for s <- statements, s.type == "def", s.term, do: s.term),
        MapSet.new(global_defs, & &1.term)
      )

    term_errors = term_errors(statements, & &1.artifact_id, terms_in_scope)
    {statements, shape_errors, warnings} = shape_pass(statements, & &1.artifact_id)

    case id_form_errors ++
           dup_errors ++ dangling_errors ++ cycle_errors ++ term_errors ++ shape_errors do
      [] -> {:ok, statements, warnings}
      errors -> {:error, errors, warnings}
    end
  end

  @doc """
  Gate one operator-authored statement against the store (deps already
  resolved to sids by the caller, which reports dangling deps itself —
  the operator's arg surface accepts sids, which the gate never sees from
  models). Subject is the statement's type until an id is assigned.
  """
  def check_operator(%Statement{} = s, fold) do
    terms_in_scope =
      fold.chains
      |> Enum.map(fn {_id, sids} -> fold.statements[List.last(sids)] end)
      |> Enum.filter(&(&1.type == "def" and &1.state in ["proposed", "ratified"]))
      |> MapSet.new(& &1.term)

    subject = fn _ -> s.display_id || s.type end
    term_errors = term_errors([s], subject, terms_in_scope)
    {[s], shape_errors, warnings} = shape_pass([s], subject)

    case shape_errors ++ term_errors do
      [] -> {:ok, s, warnings}
      errors -> {:error, errors, warnings}
    end
  end

  defp term_errors(statements, subject, terms_in_scope) do
    for s <- statements,
        term <- Statement.terms_in(s.body || ""),
        not MapSet.member?(terms_in_scope, term),
        do: finding("E_TERM_UNDEF", subject.(s), "term *#{term}* has no def in scope")
  end

  # Shape lint (E_DEF_NO_SCOPE, E_REF_NO_ORIGIN, W_DEF_ATOMICITY) plus file
  # origin hashing — app-resolved at gate time.
  defp shape_pass(statements, subject) do
    results =
      Enum.map(statements, fn s ->
        {errors, warnings} = Statement.lint(s)
        errors = Enum.map(errors, &%{&1 | subject: subject.(s)})
        warnings = Enum.map(warnings, &%{&1 | subject: subject.(s)})

        case {errors, hash_origin(s)} do
          {[], {:ok, s}} -> {s, [], warnings}
          {[], {:error, e}} -> {s, [%{e | subject: subject.(s)}], warnings}
          {errors, _} -> {s, errors, warnings}
        end
      end)

    {
      Enum.map(results, &elem(&1, 0)),
      Enum.flat_map(results, &elem(&1, 1)),
      Enum.flat_map(results, &elem(&1, 2))
    }
  end

  defp hash_origin(%{origin: %{kind: "file", locator: path, sha256: nil} = origin} = s) do
    case File.read(path) do
      {:ok, bytes} ->
        sha = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
        {:ok, %{s | origin: %{origin | sha256: sha}}}

      {:error, _} ->
        {:error, finding("E_REF_NO_ORIGIN", nil, "file #{path} not found")}
    end
  end

  defp hash_origin(s), do: {:ok, s}

  defp finding(code, subject, detail), do: %{code: code, subject: subject, detail: detail}
end
