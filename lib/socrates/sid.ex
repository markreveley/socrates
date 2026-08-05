defmodule Socrates.Sid do
  @moduledoc """
  ULID generation, stdlib only (`:crypto` is OTP). 48-bit millisecond
  timestamp + 80 bits of randomness, Crockford base32, 26 chars,
  lexicographically sortable by generation time.
  """

  @alphabet ~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ"

  def generate(ms \\ System.system_time(:millisecond)) do
    encode(<<0::2, ms::48, :crypto.strong_rand_bytes(10)::binary>>)
  end

  @doc "26 chars of the Crockford alphabet (the sid surface form)."
  def valid?(s) when is_binary(s) do
    byte_size(s) == 26 and s |> String.to_charlist() |> Enum.all?(&(&1 in @alphabet))
  end

  def valid?(_), do: false

  defp encode(bits), do: for(<<index::5 <- bits>>, into: "", do: <<Enum.at(@alphabet, index)>>)
end
