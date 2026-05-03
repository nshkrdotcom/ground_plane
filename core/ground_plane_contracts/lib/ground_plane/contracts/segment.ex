defmodule GroundPlane.Contracts.Segment do
  @moduledoc false

  @spec owner?(term()) :: boolean()
  def owner?(value) when is_binary(value), do: valid_segment?(value, :owner)
  def owner?(_value), do: false

  @spec name?(term()) :: boolean()
  def name?(value) when is_binary(value), do: valid_segment?(value, :name)
  def name?(_value), do: false

  @spec artifact_name?(term()) :: boolean()
  def artifact_name?(value) when is_binary(value), do: valid_segment?(value, :artifact_name)
  def artifact_name?(_value), do: false

  @spec id?(term()) :: boolean()
  def id?(value) when is_binary(value), do: id_bytes?(value, false, true)
  def id?(_value), do: false

  @spec normalize_id_segment(String.t()) :: String.t()
  def normalize_id_segment(segment) when is_binary(segment) do
    segment
    |> String.downcase()
    |> normalize_id_bytes([], false)
  end

  defp valid_segment?(<<>>, _kind), do: false

  defp valid_segment?(<<first, rest::binary>>, kind) do
    start_allowed?(kind, first) and rest_allowed?(rest, kind)
  end

  defp rest_allowed?(<<>>, _kind), do: true

  defp rest_allowed?(<<byte, rest::binary>>, kind) do
    segment_byte_allowed?(kind, byte) and rest_allowed?(rest, kind)
  end

  defp start_allowed?(:owner, byte), do: ascii_lower_or_digit?(byte)
  defp start_allowed?(_kind, byte), do: ascii_alnum?(byte)

  defp segment_byte_allowed?(:owner, byte), do: ascii_lower_or_digit?(byte) or byte in [?_, ?-]
  defp segment_byte_allowed?(:artifact_name, byte), do: ascii_alnum?(byte) or byte in [?_, ?-, ?.]
  defp segment_byte_allowed?(_kind, byte), do: ascii_alnum?(byte) or byte in [?_, ?-]

  defp id_bytes?(<<>>, seen_separator, previous_separator) do
    seen_separator and not previous_separator
  end

  defp id_bytes?(<<"_", _rest::binary>>, _seen_separator, true), do: false

  defp id_bytes?(<<"_", rest::binary>>, _seen_separator, false) do
    id_bytes?(rest, true, true)
  end

  defp id_bytes?(<<byte, rest::binary>>, seen_separator, _previous_separator) do
    ascii_lower_or_digit?(byte) and id_bytes?(rest, seen_separator, false)
  end

  defp normalize_id_bytes(<<>>, acc, last_separator), do: finish_normalized(acc, last_separator)

  defp normalize_id_bytes(<<byte, rest::binary>>, acc, last_separator) do
    if ascii_lower_or_digit?(byte) do
      normalize_id_bytes(rest, [<<byte>> | acc], false)
    else
      cond do
        acc == [] -> normalize_id_bytes(rest, acc, true)
        last_separator -> normalize_id_bytes(rest, acc, true)
        true -> normalize_id_bytes(rest, ["_" | acc], true)
      end
    end
  end

  defp finish_normalized(["_" | rest], true), do: rest |> Enum.reverse() |> IO.iodata_to_binary()
  defp finish_normalized(acc, _last_separator), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp ascii_alnum?(byte), do: ascii_lower_or_digit?(byte) or byte in ?A..?Z
  defp ascii_lower_or_digit?(byte), do: byte in ?a..?z or byte in ?0..?9
end
