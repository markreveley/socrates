defmodule Socrates.StatementTest do
  use ExUnit.Case, async: true

  alias Socrates.Statement

  describe "lint" do
    test "def without scope is E_DEF_NO_SCOPE" do
      {errors, _} = Statement.lint(%Statement{type: "def", term: "x", body: "b"})
      assert [%{code: "E_DEF_NO_SCOPE", subject: "def"}] = errors
    end

    test "def with bad scope is E_DEF_NO_SCOPE" do
      {errors, _} = Statement.lint(%Statement{type: "def", term: "x", scope: "purple", body: "b"})
      assert [%{code: "E_DEF_NO_SCOPE"}] = errors
    end

    test "ref without origin is E_REF_NO_ORIGIN" do
      {errors, _} = Statement.lint(%Statement{type: "ref", body: "b"})
      assert [%{code: "E_REF_NO_ORIGIN", subject: "ref"}] = errors
    end

    test "ref with unknown origin kind is E_REF_NO_ORIGIN" do
      {errors, _} =
        Statement.lint(%Statement{
          type: "ref",
          body: "b",
          origin: %{kind: "carrier-pigeon", locator: "x", sha256: nil}
        })

      assert [%{code: "E_REF_NO_ORIGIN"}] = errors
    end

    test "attest with body and no extras is clean" do
      assert {[], []} = Statement.lint(%Statement{type: "attest", body: "apples are fruits"})
    end

    test "multi-sentence def body warns W_DEF_ATOMICITY without blocking" do
      {errors, warnings} =
        Statement.lint(%Statement{
          type: "def",
          term: "x",
          scope: "local",
          body: "First sentence. Second sentence."
        })

      assert errors == []
      assert [%{code: "W_DEF_ATOMICITY", detail: "def body reads multi-sentence"}] = warnings
    end

    test "clause-conjoined def body warns W_DEF_ATOMICITY" do
      {_, warnings} =
        Statement.lint(%Statement{type: "def", term: "x", scope: "local", body: "one; two"})

      assert [%{code: "W_DEF_ATOMICITY", detail: "def body reads clause-conjoined"}] = warnings
    end

    test "subject prefers display id when assigned" do
      {errors, _} =
        Statement.lint(%Statement{type: "def", term: "x", body: "b", display_id: "def_3"})

      assert [%{subject: "def_3"}] = errors
    end
  end

  describe "terms_in — the reserved *…* surface" do
    test "finds terms, uniquely" do
      assert Statement.terms_in("*a* uses *b* and *a*") == ["a", "b"]
    end

    test "multi-word terms" do
      assert Statement.terms_in("x *representation ratification* y") ==
               ["representation ratification"]
    end

    test "asymmetric delimiters do not scan (canon claim_2's *…\" case)" do
      assert Statement.terms_in(~s(*Sounds like you know what you are doing" is a failure)) == []
    end

    test "terms do not span lines" do
      assert Statement.terms_in("*a\nb*") == []
    end
  end
end
