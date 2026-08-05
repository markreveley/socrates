defmodule Socrates.SidTest do
  use ExUnit.Case, async: true

  alias Socrates.Sid

  test "26 chars of the Crockford alphabet" do
    sid = Sid.generate()
    assert byte_size(sid) == 26
    assert Sid.valid?(sid)
  end

  test "sorts by generation time" do
    early = Sid.generate(1_000_000)
    late = Sid.generate(2_000_000)
    assert early < late
  end

  test "unique across a burst" do
    sids = for _ <- 1..1000, do: Sid.generate()
    assert length(Enum.uniq(sids)) == 1000
  end

  test "valid? refuses display ids, short strings, and lowercase" do
    refute Sid.valid?("attest_1")
    refute Sid.valid?("01ARZ3NDEKTSV4RRFFQ69G5FA")
    refute Sid.valid?(String.downcase(Sid.generate()))
    # I, L, O, U are not in the Crockford alphabet
    refute Sid.valid?(String.duplicate("I", 26))
  end
end
