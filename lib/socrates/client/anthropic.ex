defmodule Socrates.Client.Anthropic do
  @moduledoc """
  The live client: `POST https://api.anthropic.com/v1/messages` via Req.

  Escript TLS (audit B1): castore's bundle lives in a `priv/` dir escripts
  do not ship, so the transport passes the OS trust store explicitly —
  `cacerts: :public_key.cacerts_get()`, available because OTP ≥ 27 is
  pinned. The request body is sent as raw bytes (`body:`, never `json:` —
  re-encoding could diverge from the digested bytes). Req does not retry
  POSTs; transport failure surfaces to the caller (exit 2 at the CLI).
  `HTTPS_PROXY`/`https_proxy` is honored when the environment sets it.
  """

  @behaviour Socrates.Client

  @url "https://api.anthropic.com/v1/messages"

  @impl true
  def call(body, _config) do
    {:ok, _} = Application.ensure_all_started(:req)

    key = System.get_env("ANTHROPIC_API_KEY")

    request =
      Req.new(
        url: @url,
        method: :post,
        headers: [
          {"x-api-key", key},
          {"anthropic-version", "2023-06-01"},
          {"content-type", "application/json"}
        ],
        body: body,
        retry: false,
        decode_body: false,
        receive_timeout: 600_000,
        connect_options: connect_options()
      )

    case Req.request(request) do
      {:ok, %Req.Response{} = resp} ->
        {:ok,
         %{
           status: resp.status,
           body: IO.iodata_to_binary(resp.body),
           request_id: resp |> Req.Response.get_header("request-id") |> List.first()
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  defp connect_options do
    transport = [transport_opts: [cacerts: :public_key.cacerts_get()]]

    case System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      nil ->
        transport

      proxy_url ->
        uri = URI.parse(proxy_url)
        transport ++ [proxy: {:http, uri.host, uri.port, []}]
    end
  end
end
