defmodule GroundPlane.Contracts.ContentAddressTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.ContentAddress

  test "builds a canonical content address from boundary payloads" do
    left = %{"b" => ["two"], "a" => %{"nested" => "one"}}
    right = %{"a" => %{"nested" => "one"}, "b" => ["two"]}

    assert {:ok, left_address} = ContentAddress.from_term(left)
    assert {:ok, right_address} = ContentAddress.from_term(right)

    assert left_address == right_address
    assert left_address.content_hash =~ ~r/^sha256:[0-9a-f]{64}$/
    assert left_address.content_hash_algorithm == "sha256"
    assert left_address.codec == "ground_plane.boundary.codec.v1"
    assert left_address.byte_size > 0
  end

  test "serializes as a primitive map without higher-layer semantics" do
    assert {:ok, address} = ContentAddress.from_term(%{"artifact" => "ref"})

    assert ContentAddress.to_map(address) == %{
             "byte_size" => address.byte_size,
             "codec" => "ground_plane.boundary.codec.v1",
             "content_hash" => address.content_hash,
             "content_hash_algorithm" => "sha256",
             "media_type" => "application/vnd.ground-plane.boundary+json"
           }

    refute Map.has_key?(ContentAddress.to_map(address), "context_ref")
    refute Map.has_key?(ContentAddress.to_map(address), "model_ref")
    refute Map.has_key?(ContentAddress.to_map(address), "prompt_ref")
  end

  test "can wrap externally encoded bytes with explicit codec and media type" do
    bytes = ~s({"already":"encoded"})

    assert {:ok, address} =
             ContentAddress.from_bytes(bytes,
               codec: "external.canonical.fixture.v1",
               media_type: "application/json"
             )

    assert address.byte_size == byte_size(bytes)
    assert address.codec == "external.canonical.fixture.v1"
    assert address.media_type == "application/json"
  end

  test "rejects local runtime values and sensitive payload keys through boundary codec" do
    assert {:error, :boundary_pid_not_serializable} = ContentAddress.from_term(self())

    assert {:error, {:raw_credential_key_forbidden, "secret"}} =
             ContentAddress.from_term(%{"secret" => "not allowed"})
  end

  test "validates explicit address attributes" do
    valid_hash = "sha256:" <> String.duplicate("a", 64)

    assert {:ok, address} =
             ContentAddress.new(%{
               content_hash: valid_hash,
               content_hash_algorithm: "sha256",
               byte_size: 42,
               codec: "fixture.codec.v1",
               media_type: "application/octet-stream"
             })

    assert address.content_hash == valid_hash

    assert {:error, :invalid_content_hash} =
             ContentAddress.new(%{
               content_hash: "sha256:not-hex",
               content_hash_algorithm: "sha256",
               byte_size: 42
             })

    assert {:error, :invalid_content_hash_algorithm} =
             ContentAddress.new(%{
               content_hash: valid_hash,
               content_hash_algorithm: "sha512",
               byte_size: 42
             })

    assert {:error, :invalid_byte_size} =
             ContentAddress.new(%{
               content_hash: valid_hash,
               content_hash_algorithm: "sha256",
               byte_size: -1
             })
  end
end
