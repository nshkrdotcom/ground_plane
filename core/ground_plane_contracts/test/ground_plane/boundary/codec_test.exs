defmodule GroundPlane.Boundary.CodecTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Boundary.Codec
  alias GroundPlane.Boundary.Fixtures

  test "canonical encoding is stable across map key order" do
    left = %{tenant_id: "tenant-a", payload: %{b: 2, a: 1}}
    right = %{"payload" => %{"a" => 1, "b" => 2}, "tenant_id" => "tenant-a"}

    assert Codec.encode!(left) == Codec.encode!(right)
    assert Codec.digest(left) == Codec.digest(right)
    assert String.starts_with?(Codec.digest(left), "sha256:")
  end

  test "boundary hashes do not use inspect, Erlang term serialization, or insertion-order JSON" do
    term = %{tenant_id: "tenant-a", payload: %{b: 2, a: 1}}

    refute Codec.digest(term) == sha256(inspect(term))
    refute Codec.digest(term) == sha256(:erlang.term_to_binary(term))
    assert Codec.encode!(%{"b" => 2, "a" => 1}) == ~s({"a":1,"b":2})
    refute Codec.encode!(%{"b" => 2, "a" => 1}) == ~s({"b":2,"a":1})
  end

  test "decode returns binary keys without atom creation" do
    assert %{"tenant_id" => "tenant-a", "payload" => %{"limit" => 2}} =
             Codec.decode!(~s({"payload":{"limit":2},"tenant_id":"tenant-a"}))
  end

  test "rejects ambiguous atom and binary map keys" do
    term = Fixtures.negative_terms().atom_binary_key_ambiguity

    assert {:error, {:ambiguous_boundary_map_key, "tenant_id"}} = Codec.encode(term)
  end

  test "rejects raw credential material" do
    term = Fixtures.negative_terms().raw_credential

    assert {:error, {:raw_credential_key_forbidden, "api_key"}} = Codec.encode(term)
  end

  test "rejects local runtime values" do
    negatives = Fixtures.negative_terms()

    assert {:error, :boundary_pid_not_serializable} = Codec.encode(negatives.unsupported_pid)

    assert {:error, :boundary_reference_not_serializable} =
             Codec.encode(negatives.unsupported_reference)

    assert {:error, :boundary_task_not_serializable} = Codec.encode(negatives.unsupported_task)

    assert {:error, :boundary_stream_not_serializable} =
             Codec.encode(negatives.unsupported_stream)
  end

  test "rejects ports" do
    port = Port.open({:spawn, "cat"}, [:binary])

    try do
      assert {:error, :boundary_port_not_serializable} = Codec.encode(%{port: port})
    after
      Port.close(port)
    end
  end

  test "fixture corpus is canonical and digestable" do
    for term <- Fixtures.canonical_terms() do
      encoded = Codec.encode!(term)

      assert is_binary(encoded)
      assert String.starts_with?(Codec.digest(term), "sha256:")
    end
  end

  defp sha256(value) do
    "sha256:" <> Base.encode16(:crypto.hash(:sha256, value), case: :lower)
  end
end
