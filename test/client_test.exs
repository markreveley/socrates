defmodule Socrates.ClientTest do
  use ExUnit.Case, async: false

  alias Socrates.{Client, Journal}
  alias Socrates.Client.Fixture

  describe "build_request — the hand-assembled request (plan 0001 → Inference)" do
    test "model, max_tokens, no thinking key, structured output, cached system tail" do
      request = Client.build_request([%{"role" => "user", "content" => "prose"}], [])

      assert request["model"] == "claude-opus-5"
      assert request["max_tokens"] == 16_000
      refute Map.has_key?(request, "thinking")

      [spec_block, defs_block] = request["system"]
      assert spec_block["type"] == "text"
      assert defs_block["cache_control"] == %{"type" => "ephemeral"}

      assert request["output_config"]["format"]["type"] == "json_schema"
      assert request["output_config"]["format"]["schema"] == Socrates.Loadout.schema()
    end

    test "SOCRATES_MODEL overrides the model" do
      System.put_env("SOCRATES_MODEL", "claude-test-1")
      request = Client.build_request([], [])
      assert request["model"] == "claude-test-1"
    after
      System.delete_env("SOCRATES_MODEL")
    end

    test "definitions reach the system prompt with display ids" do
      request =
        Client.build_request([], [
          %{
            display_id: "def_1",
            term: "representation ratification",
            body: "the operator verifying"
          }
        ])

      [_, defs_block] = request["system"]
      assert defs_block["text"] =~ "[def_1] *representation ratification*: the operator verifying"
    end

    test "encode_request is byte-deterministic" do
      request = Client.build_request([%{"role" => "user", "content" => "same"}], [])
      assert Client.encode_request(request) == Client.encode_request(request)
    end
  end

  describe "fixture client" do
    defp first_request(source) do
      Client.build_request([%{"role" => "user", "content" => source}], [])
      |> Client.encode_request()
    end

    test "honest provenance: model fixture, zero usage, end_turn, no request id" do
      {:ok, response} = Fixture.call(first_request("anything at all"), %{path: nil})
      assert response.status == 200
      assert response.request_id == nil

      body = JSON.decode!(response.body)
      assert body["model"] == "fixture"
      assert body["stop_reason"] == "end_turn"
      assert body["usage"] == %{"input_tokens" => 0, "output_tokens" => 0}
    end

    test "canon source: first response uses the coined term without a def; repair adds def_2" do
      {:ok, response} =
        Fixture.call(first_request("x *representation ratification* y"), %{path: nil})

      artifact = JSON.decode!(hd(JSON.decode!(response.body)["content"])["text"])

      ids = Enum.map(artifact["statements"], & &1["display_id"])
      assert ids == ~w(attest_1 attest_2 attest_3 attest_4)

      repair_messages = [
        %{"role" => "user", "content" => "x *representation ratification* y"},
        %{"role" => "assistant", "content" => "…"},
        %{"role" => "user", "content" => "{\"gate_errors\": []}"}
      ]

      {:ok, response} =
        Fixture.call(Client.encode_request(Client.build_request(repair_messages, [])), %{
          path: nil
        })

      artifact = JSON.decode!(hd(JSON.decode!(response.body)["content"])["text"])
      ids = Enum.map(artifact["statements"], & &1["display_id"])
      assert ids == ~w(attest_1 attest_2 attest_3 attest_4 def_2)

      def_2 = List.last(artifact["statements"])
      assert def_2["term"] == "Sounds like you know what you are doing"
      assert def_2["scope"] == "local"
    end

    test "non-canon source: the artifact dangles on every round" do
      for messages <- [
            [%{"role" => "user", "content" => "gibberish"}],
            [
              %{"role" => "user", "content" => "gibberish"},
              %{"role" => "assistant", "content" => "…"},
              %{"role" => "user", "content" => "{\"gate_errors\": []}"}
            ]
          ] do
        {:ok, response} =
          Fixture.call(Client.encode_request(Client.build_request(messages, [])), %{path: nil})

        artifact = JSON.decode!(hd(JSON.decode!(response.body)["content"])["text"])
        assert [%{"deps" => []}, %{"deps" => ["attest_9"]}] = artifact["statements"]
      end
    end

    test "path mode serves responses by call index, last repeats" do
      dir = System.tmp_dir!()
      path = Path.join(dir, "socrates-fixture-#{System.unique_integer([:positive])}.json")

      File.write!(
        path,
        JSON.encode!([
          %{"marker" => 1, "content" => [], "stop_reason" => "end_turn"},
          %{"marker" => 2, "content" => [], "stop_reason" => "end_turn"}
        ])
      )

      on_exit(fn -> File.rm(path) end)

      {:ok, r1} = Fixture.call(first_request("x"), %{path: path})
      assert JSON.decode!(r1.body)["marker"] == 1

      repair = [
        %{"role" => "user", "content" => "x"},
        %{"role" => "assistant", "content" => "…"},
        %{"role" => "user", "content" => "{}"}
      ]

      {:ok, r2} =
        Fixture.call(Client.encode_request(Client.build_request(repair, [])), %{path: path})

      assert JSON.decode!(r2.body)["marker"] == 2

      third =
        repair ++
          [%{"role" => "assistant", "content" => "…"}, %{"role" => "user", "content" => "{}"}]

      {:ok, r3} =
        Fixture.call(Client.encode_request(Client.build_request(third, [])), %{path: path})

      assert JSON.decode!(r3.body)["marker"] == 2
    end

    test "fixture responses archive byte-identically across calls" do
      {:ok, a} = Fixture.call(first_request("same input"), %{path: nil})
      {:ok, b} = Fixture.call(first_request("same input"), %{path: nil})
      assert a.body == b.body
    end
  end

  test "request sha256 in provenance covers exactly the bytes sent" do
    request = Client.build_request([%{"role" => "user", "content" => "prose"}], [])
    bytes = Client.encode_request(request)
    # decode/re-encode through the deterministic encoder is byte-identical,
    # so the digest is reproducible from the journal alone
    assert Journal.emit(JSON.decode!(bytes)) == bytes
  end
end
