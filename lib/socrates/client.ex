defmodule Socrates.Client do
  @moduledoc """
  The inference transport behaviour, plus the hand-assembled request.

  A client takes the exact request-body bytes (already encoded — the
  provenance digest covers exactly the bytes sent) and returns the raw
  response-body bytes (archived byte-exact) with transport metadata.
  Implementations: `Socrates.Client.Anthropic` (live, Req) and
  `Socrates.Client.Fixture` (canned; every test but the optional live smoke
  runs against it). Selection: `SOCRATES_CLIENT=fixture[:<path>]`, default
  `anthropic`.
  """

  alias Socrates.{Journal, Loadout}

  @type response :: %{status: non_neg_integer(), body: binary(), request_id: String.t() | nil}

  @callback call(body :: binary(), config :: map()) :: {:ok, response()} | {:error, term()}

  @default_model "claude-opus-5"

  def default_model, do: @default_model

  @doc """
  The request body as a deterministic map: model (`SOCRATES_MODEL` or the
  default), `max_tokens: 16000`, `thinking` omitted (on by default for this
  model), system blocks from the loadout (cache_control ephemeral on the
  last), structured output against the loadout schema. Encode with
  `Journal.emit/1` and digest those bytes — never re-encode.
  """
  def build_request(messages, definitions) do
    %{
      "model" => System.get_env("SOCRATES_MODEL", @default_model),
      "max_tokens" => 16_000,
      "system" => Loadout.system_blocks(definitions),
      "messages" => messages,
      "output_config" => %{
        "format" => %{"type" => "json_schema", "schema" => Loadout.schema()}
      }
    }
  end

  @doc "Deterministic request bytes (sorted-key JSON via the journal encoder)."
  def encode_request(request_map), do: Journal.emit(request_map)
end
