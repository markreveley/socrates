defmodule Socrates.Render do
  @moduledoc """
  Bracket notation to stdout. One line per statement:

      ⊢ [attest_1] apples are fruits
        [attest_4](attest_1, attest_2) body   {note}

  `⊢` on `state: ratified` only (D4, display-only; `--ascii` renders `|-`);
  non-ratified statements indent to the same column. Defs render as
  `[def_1] *term* {notes} : body`. Notes are dimmed when ANSI is on (never
  in pipes — stdout stays byte-clean, D6). A `[basis: …]` slot exists for a
  field no v0 statement carries. Continuation lines (bodies with embedded
  newlines) indent two spaces.

  Document order is topological, defs and refs first — computed by the
  renderer via `Socrates.Graph` (Kahn; ready-set ties broken defs/refs
  first, then journal order), never requested of the model.
  """

  alias Socrates.Graph

  @doc """
  The rendered document for a list of statements (already selected, journal
  order). `display` maps a dep sid to its display id.
  """
  def document(statements, display, opts \\ []) do
    statements
    |> Graph.topo_sort(fn s -> Enum.map(s.deps, display) end, & &1.display_id)
    |> Enum.map(&line(&1, display, opts))
    |> Enum.map(&[&1, "\n"])
    |> IO.iodata_to_binary()
  end

  @doc "One statement's rendered line (no trailing newline)."
  def line(s, display, opts \\ []) do
    ascii = Keyword.get(opts, :ascii, false)

    prefix =
      case {s.state, ascii} do
        {"ratified", false} -> "⊢ "
        {"ratified", true} -> "|- "
        {_, false} -> "  "
        {_, true} -> "   "
      end

    deps =
      case s.deps do
        [] -> ""
        sids -> "(" <> Enum.join(Enum.map(sids, display), ", ") <> ")"
      end

    notes =
      case s.notes do
        [] -> nil
        notes -> dim("{" <> Enum.join(notes, "; ") <> "}", opts)
      end

    basis =
      case Map.get(s, :basis) do
        nil -> nil
        basis -> "[basis: " <> basis <> "]"
      end

    body =
      case s.type do
        "def" ->
          Enum.join(["*#{s.term}*"] ++ List.wrap(notes) ++ [": #{s.body}"], " ")

        _ ->
          Enum.join(
            [s.body] ++ Enum.map(List.wrap(notes) ++ List.wrap(basis), &("  " <> &1)),
            " "
          )
      end

    (prefix <> "[#{s.display_id}]" <> deps <> " " <> body)
    |> String.split("\n")
    |> Enum.join("\n  ")
  end

  defp dim(text, opts) do
    if Keyword.get(opts, :ansi, false) do
      IO.ANSI.faint() <> text <> IO.ANSI.reset()
    else
      text
    end
  end
end
