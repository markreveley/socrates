defmodule Socrates.Client.Fixture do
  @moduledoc """
  The canned client. Provenance stays honest: responses carry
  `model: "fixture"`, no request id, zero usage — never a real model id
  (audit A4). Responses are archived byte-exact like live ones.

  Two modes:

  - `SOCRATES_CLIENT=fixture` — built-in responses. A source carrying canon
    #1's marker (`*representation ratification*`) is served the
    acceptance sequence (audit A3): a first decomposition whose coined term
    has no def — the gate finds exactly `E_TERM_UNDEF` on the artifact's
    third attest — then, on the repair turn, the corrected artifact with
    the minted def. Any other source is served a persistently broken
    artifact (a dep on `attest_9` that nothing defines) for the
    forced-failure walk (scenario 5).
  - `SOCRATES_CLIENT=fixture:<path>` — `<path>` is a JSON array of full
    API-shaped response bodies, served in call order (the last one
    repeats). For tests that need arbitrary behavior (stop_reason,
    malformed artifacts).
  """

  @behaviour Socrates.Client

  alias Socrates.Journal

  @impl true
  def call(body, config) do
    request = JSON.decode!(body)

    response_map =
      case config do
        %{path: nil} -> built_in(request)
        %{path: path} -> from_path(path, request)
      end

    {:ok, %{status: 200, body: Journal.emit(response_map), request_id: nil}}
  end

  defp from_path(path, request) do
    responses = path |> File.read!() |> JSON.decode!()
    call_index = div(length(request["messages"]) - 1, 2)
    Enum.at(responses, call_index) || List.last(responses)
  end

  defp built_in(request) do
    [%{"content" => source} | _] = request["messages"]
    repair_round = div(length(request["messages"]) - 1, 2)

    artifact =
      cond do
        String.contains?(source, "*representation ratification*") and repair_round == 0 ->
          canon_first()

        String.contains?(source, "*representation ratification*") ->
          canon_repaired()

        true ->
          persistently_broken()
      end

    response(artifact)
  end

  defp response(artifact) do
    %{
      "id" => "msg_fixture",
      "type" => "message",
      "role" => "assistant",
      "model" => "fixture",
      "stop_reason" => "end_turn",
      "content" => [%{"type" => "text", "text" => Journal.emit(artifact)}],
      "usage" => %{"input_tokens" => 0, "output_tokens" => 0}
    }
  end

  # Canon #1 decomposed, artifact-local ids, inline `(def_0)` notation
  # artifacts stripped into dep edges on the store's def_1 (visible in the
  # definitions block). The coined term is used but not defined — the IOU
  # the gate refuses (E_TERM_UNDEF on attest_3).
  defp canon_first do
    %{"statements" => canon_attests(false)}
  end

  # The repair: the same four attests, the minted def appended, and the
  # dependency edge added (canon's annotation names exactly this repair).
  defp canon_repaired do
    %{
      "statements" =>
        canon_attests(true) ++
          [
            %{
              "display_id" => "def_2",
              "type" => "def",
              "term" => "Sounds like you know what you are doing",
              "scope" => "local",
              "body" =>
                "the operator failure of approving semantically dense and opaque agent output on the assumption that the agent knows what it is doing",
              "deps" => [],
              "notes" => ["coinable local, candidate for global filing"]
            }
          ]
    }
  end

  defp canon_attests(repaired?) do
    [
      %{
        "display_id" => "attest_1",
        "type" => "attest",
        "body" =>
          "*representation ratification* is a process whereby intent by the agent is ratified as a checkable artifact by the operator",
        "deps" => ["def_1"],
        "notes" => []
      },
      %{
        "display_id" => "attest_2",
        "type" => "attest",
        "body" =>
          "*representation ratification* is a process whereby socratic agent output is audited against socratic ratified intent statements",
        "deps" => ["def_1", "attest_1"],
        "notes" => []
      },
      %{
        "display_id" => "attest_3",
        "type" => "attest",
        "body" =>
          "*Sounds like you know what you are doing* is an operator failure when the combination of semantically dense and opaque communication which is expensive to unpack is left unpacked in favor of assuming the agent \"knows what its doing\", incentivizing the easier path of default approving",
        "deps" => if(repaired?, do: ["def_1", "def_2"], else: ["def_1"]),
        "notes" => ["coinable local, candidate for global filing"]
      },
      %{
        "display_id" => "attest_4",
        "type" => "attest",
        "body" =>
          "*representation ratification* converts \"sounds like you know what you're doing, keep going\" into a set of discrete decisions the operator approves or rejects one at a time.\"",
        "deps" => ["def_1", "attest_2", "attest_3"],
        "notes" => []
      }
    ]
  end

  # Scenario 5: an artifact whose second statement leans on nothing, and a
  # model that never fixes it — the gate exhausts its repairs and the run
  # fails loudly.
  defp persistently_broken do
    %{
      "statements" => [
        %{
          "display_id" => "attest_1",
          "type" => "attest",
          "body" => "this input decomposes badly",
          "deps" => [],
          "notes" => []
        },
        %{
          "display_id" => "attest_2",
          "type" => "attest",
          "body" => "its second statement leans on nothing",
          "deps" => ["attest_9"],
          "notes" => []
        }
      ]
    }
  end
end
