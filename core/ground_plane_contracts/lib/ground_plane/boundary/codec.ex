defmodule GroundPlane.Boundary.Codec do
  @moduledoc """
  Canonical boundary codec for cross-plane protocol payloads.

  The codec intentionally decodes maps with binary keys only. Atom keys may be
  encoded from trusted in-memory structs, but external input never creates
  atoms during decode.
  """

  alias GroundPlane.Boundary.DispatchResult
  alias GroundPlane.Boundary.Envelope
  alias GroundPlane.BoundaryProtocol.CommandEnvelope

  @sensitive_keys MapSet.new([
                    "access_token",
                    "api_key",
                    "client_secret",
                    "credential_material",
                    "material",
                    "private_key",
                    "raw_credential",
                    "refresh_token",
                    "secret",
                    "token",
                    "webhook_secret"
                  ])

  @type canonical_value ::
          nil
          | boolean()
          | integer()
          | String.t()
          | [canonical_value()]
          | %{String.t() => canonical_value()}

  @spec encode(term()) :: {:ok, String.t()} | {:error, term()}
  def encode(term) do
    with {:ok, normalized} <- normalize(term) do
      {:ok, canonical_json(normalized)}
    end
  end

  @spec encode!(term()) :: String.t()
  def encode!(term) do
    case encode(term) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise ArgumentError, "unsupported boundary payload: #{inspect(reason)}"
    end
  end

  @spec decode(String.t()) :: {:ok, canonical_value()} | {:error, term()}
  def decode(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, decoded} -> normalize_decoded(decoded)
      {:error, reason} -> {:error, {:invalid_boundary_json, reason}}
    end
  end

  def decode(_other), do: {:error, :boundary_payload_not_binary}

  @spec decode!(String.t()) :: canonical_value()
  def decode!(binary) do
    case decode(binary) do
      {:ok, decoded} -> decoded
      {:error, reason} -> raise ArgumentError, "invalid boundary payload: #{inspect(reason)}"
    end
  end

  @spec digest(term()) :: String.t()
  def digest(term) do
    "sha256:" <>
      (term
       |> encode!()
       |> then(&:crypto.hash(:sha256, &1))
       |> Base.encode16(case: :lower))
  end

  @spec normalize(term()) :: {:ok, canonical_value()} | {:error, term()}
  def normalize(%CommandEnvelope{} = envelope),
    do: envelope |> CommandEnvelope.to_map() |> normalize()

  def normalize(%Envelope{} = envelope), do: envelope |> Envelope.to_map() |> normalize()
  def normalize(%DispatchResult{} = result), do: result |> DispatchResult.to_map() |> normalize()
  def normalize(nil), do: {:ok, nil}
  def normalize(value) when is_boolean(value), do: {:ok, value}
  def normalize(value) when is_integer(value), do: {:ok, value}
  def normalize(value) when is_binary(value), do: {:ok, value}

  def normalize(value) when is_atom(value),
    do: {:error, {:unsupported_boundary_value, :atom_value, value}}

  def normalize(value) when is_float(value),
    do: {:error, {:unsupported_boundary_value, :float, value}}

  def normalize(value) when is_pid(value), do: {:error, :boundary_pid_not_serializable}

  def normalize(value) when is_reference(value),
    do: {:error, :boundary_reference_not_serializable}

  def normalize(value) when is_port(value), do: {:error, :boundary_port_not_serializable}
  def normalize(value) when is_function(value), do: {:error, :boundary_function_not_serializable}

  def normalize(%Task{}), do: {:error, :boundary_task_not_serializable}
  def normalize(%Stream{}), do: {:error, :boundary_stream_not_serializable}
  def normalize(%_struct{}), do: {:error, :boundary_struct_not_serializable}

  def normalize(list) when is_list(list) do
    list
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, acc} ->
      case normalize(value) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end

  def normalize(map) when is_map(map) do
    map
    |> Enum.reduce_while({:ok, %{}}, &normalize_pair/2)
  end

  def normalize(_other), do: {:error, :unsupported_boundary_value}

  defp normalize_pair({key, value}, {:ok, acc}) do
    with {:ok, canonical_key} <- canonical_key(key),
         :ok <- reject_sensitive_key(canonical_key),
         :ok <- reject_duplicate_key(acc, canonical_key),
         {:ok, normalized_value} <- normalize(value) do
      {:cont, {:ok, Map.put(acc, canonical_key, normalized_value)}}
    else
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp canonical_key(key) when is_binary(key) do
    if key == "", do: {:error, :empty_boundary_map_key}, else: {:ok, key}
  end

  defp canonical_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}
  defp canonical_key(_key), do: {:error, :unsupported_boundary_map_key}

  defp reject_sensitive_key(key) do
    if MapSet.member?(@sensitive_keys, key) do
      {:error, {:raw_credential_key_forbidden, key}}
    else
      :ok
    end
  end

  defp reject_duplicate_key(map, key) do
    if Map.has_key?(map, key) do
      {:error, {:ambiguous_boundary_map_key, key}}
    else
      :ok
    end
  end

  defp normalize_decoded(nil), do: {:ok, nil}
  defp normalize_decoded(value) when is_boolean(value), do: {:ok, value}
  defp normalize_decoded(value) when is_integer(value), do: {:ok, value}
  defp normalize_decoded(value) when is_binary(value), do: {:ok, value}

  defp normalize_decoded(list) when is_list(list) do
    list
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, acc} ->
      case normalize_decoded(value) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end

  defp normalize_decoded(map) when is_map(map) do
    map
    |> Enum.reduce_while({:ok, %{}}, fn {key, value}, {:ok, acc} ->
      with :ok <- reject_sensitive_key(key),
           {:ok, normalized_value} <- normalize_decoded(value) do
        {:cont, {:ok, Map.put(acc, key, normalized_value)}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_decoded(_other), do: {:error, :unsupported_decoded_boundary_value}

  defp canonical_json(nil), do: "null"
  defp canonical_json(true), do: "true"
  defp canonical_json(false), do: "false"
  defp canonical_json(value) when is_integer(value), do: Integer.to_string(value)
  defp canonical_json(value) when is_binary(value), do: Jason.encode!(value)

  defp canonical_json(list) when is_list(list) do
    "[" <> Enum.map_join(list, ",", &canonical_json/1) <> "]"
  end

  defp canonical_json(map) when is_map(map) do
    entries =
      map
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn key -> Jason.encode!(key) <> ":" <> canonical_json(Map.fetch!(map, key)) end)

    "{" <> Enum.join(entries, ",") <> "}"
  end
end
