defmodule GroundPlane.Contracts.ContentAddress do
  @moduledoc """
  Generic content-address facts for boundary-significant payloads.

  This module deliberately owns only primitive hash metadata. It does not carry
  product, model, prompt, workflow, governance, or evidence semantics.
  """

  alias GroundPlane.Boundary.Codec

  @default_codec "ground_plane.boundary.codec.v1"
  @default_media_type "application/vnd.ground-plane.boundary+json"
  @bytes_codec "external.bytes.v1"
  @bytes_media_type "application/octet-stream"

  @enforce_keys [:content_hash, :content_hash_algorithm, :byte_size, :codec, :media_type]
  defstruct [:content_hash, :content_hash_algorithm, :byte_size, :codec, :media_type]

  @type t :: %__MODULE__{
          content_hash: String.t(),
          content_hash_algorithm: String.t(),
          byte_size: non_neg_integer(),
          codec: String.t(),
          media_type: String.t()
        }

  @spec from_term(term(), keyword() | map()) :: {:ok, t()} | {:error, term()}
  def from_term(term, opts \\ []) do
    with {:ok, encoded} <- Codec.encode(term) do
      from_bytes(encoded,
        codec: option(opts, :codec, @default_codec),
        media_type: option(opts, :media_type, @default_media_type)
      )
    end
  end

  @spec from_bytes(binary(), keyword() | map()) :: {:ok, t()} | {:error, term()}
  def from_bytes(bytes, opts \\ [])

  def from_bytes(bytes, opts) when is_binary(bytes) do
    new(%{
      content_hash: sha256(bytes),
      content_hash_algorithm: "sha256",
      byte_size: byte_size(bytes),
      codec: option(opts, :codec, @bytes_codec),
      media_type: option(opts, :media_type, @bytes_media_type)
    })
  end

  def from_bytes(_bytes, _opts), do: {:error, :content_bytes_not_binary}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with {:ok, content_hash} <- fetch_string(attrs, :content_hash),
         :ok <- validate_hash(content_hash),
         {:ok, algorithm} <- fetch_string(attrs, :content_hash_algorithm),
         :ok <- validate_algorithm(algorithm),
         {:ok, byte_size} <- fetch_byte_size(attrs),
         {:ok, codec} <- optional_string(attrs, :codec, @default_codec),
         {:ok, media_type} <- optional_string(attrs, :media_type, @default_media_type) do
      {:ok,
       %__MODULE__{
         content_hash: content_hash,
         content_hash_algorithm: algorithm,
         byte_size: byte_size,
         codec: codec,
         media_type: media_type
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_content_address}

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = address) do
    %{
      "content_hash" => address.content_hash,
      "content_hash_algorithm" => address.content_hash_algorithm,
      "byte_size" => address.byte_size,
      "codec" => address.codec,
      "media_type" => address.media_type
    }
  end

  defp fetch_string(attrs, field) do
    case value(attrs, field) do
      current when is_binary(current) and current != "" -> {:ok, current}
      _other -> {:error, :"invalid_#{field}"}
    end
  end

  defp optional_string(attrs, field, default) do
    case value(attrs, field) do
      nil -> {:ok, default}
      current when is_binary(current) and current != "" -> {:ok, current}
      _other -> {:error, :"invalid_#{field}"}
    end
  end

  defp fetch_byte_size(attrs) do
    case value(attrs, :byte_size) do
      current when is_integer(current) and current >= 0 -> {:ok, current}
      _other -> {:error, :invalid_byte_size}
    end
  end

  defp validate_hash("sha256:" <> hex) do
    if byte_size(hex) == 64 and String.match?(hex, ~r/^[0-9a-f]+$/) do
      :ok
    else
      {:error, :invalid_content_hash}
    end
  end

  defp validate_hash(_hash), do: {:error, :invalid_content_hash}

  defp validate_algorithm("sha256"), do: :ok
  defp validate_algorithm(_algorithm), do: {:error, :invalid_content_hash_algorithm}

  defp option(opts, field, default) do
    opts
    |> normalize_opts()
    |> value(field)
    |> case do
      current when is_binary(current) and current != "" -> current
      _other -> default
    end
  end

  defp normalize_opts(opts) when is_list(opts), do: Map.new(opts)
  defp normalize_opts(opts) when is_map(opts), do: opts
  defp normalize_opts(_opts), do: %{}

  defp value(attrs, field), do: Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))

  defp sha256(bytes) do
    "sha256:" <> Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
  end
end
