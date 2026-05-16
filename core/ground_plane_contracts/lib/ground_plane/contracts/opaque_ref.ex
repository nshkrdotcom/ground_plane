defmodule GroundPlane.Contracts.OpaqueRef do
  @moduledoc false

  defmacro __using__(opts) do
    scheme = Keyword.fetch!(opts, :scheme)
    segment_count = Keyword.fetch!(opts, :segments)

    quote bind_quoted: [scheme: scheme, segment_count: segment_count] do
      alias GroundPlane.Contracts.OpaqueRef

      @enforce_keys [:segments, :ref]
      defstruct [:segments, :ref]
      @opaque_ref_scheme scheme
      @opaque_ref_segment_count segment_count

      @type t :: %__MODULE__{segments: [String.t()], ref: String.t()}

      @spec new(String.t()) :: {:ok, t()} | {:error, term()}
      def new(segment), do: new_segments([segment])

      @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
      def new(left, right), do: new_segments([left, right])

      @spec new(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
      def new(first, second, third), do: new_segments([first, second, third])

      @spec new(String.t(), String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
      def new(first, second, third, fourth), do: new_segments([first, second, third, fourth])

      @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
      def parse(value) do
        OpaqueRef.parse(
          __MODULE__,
          @opaque_ref_scheme,
          @opaque_ref_segment_count,
          value
        )
      end

      @spec valid?(term()) :: boolean()
      def valid?(value) when is_binary(value) do
        case parse(value) do
          {:ok, _ref} -> true
          {:error, _reason} -> false
        end
      end

      def valid?(_value), do: false

      @spec to_string(t()) :: String.t()
      def to_string(%__MODULE__{ref: ref}), do: ref

      defp new_segments(segments) do
        OpaqueRef.new(
          __MODULE__,
          @opaque_ref_scheme,
          @opaque_ref_segment_count,
          segments
        )
      end
    end
  end

  @spec new(module(), String.t(), pos_integer(), [term()]) :: {:ok, struct()} | {:error, term()}
  def new(module, scheme, segment_count, segments)
      when is_atom(module) and is_binary(scheme) and is_integer(segment_count) and
             is_list(segments) do
    with {:ok, normalized_segments} <- normalize_segments(segment_count, segments) do
      {:ok, struct(module, segments: normalized_segments, ref: ref(scheme, normalized_segments))}
    end
  end

  @spec parse(module(), String.t(), pos_integer(), String.t()) ::
          {:ok, struct()} | {:error, term()}
  def parse(module, scheme, segment_count, value)
      when is_atom(module) and is_binary(scheme) and is_integer(segment_count) and
             is_binary(value) do
    prefix = scheme <> "://"

    if String.starts_with?(value, prefix) do
      segments = value |> String.replace_prefix(prefix, "") |> String.split("/", trim: false)

      with {:ok, parsed} <- new(module, scheme, segment_count, segments),
           true <- parsed.ref == value do
        {:ok, parsed}
      else
        false -> {:error, :non_canonical_opaque_ref}
        {:error, {:invalid_segment, _index}} -> {:error, :non_canonical_opaque_ref}
        error -> error
      end
    else
      {:error, :invalid_opaque_ref}
    end
  end

  def parse(_module, _scheme, _segment_count, _value), do: {:error, :invalid_opaque_ref}

  defp normalize_segments(segment_count, segments) when length(segments) == segment_count do
    segments
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, &normalize_segment_at/2)
    |> finalize_normalized_segments()
  end

  defp normalize_segments(_segment_count, _segments), do: {:error, :invalid_opaque_ref}

  defp normalize_segment_at({segment, index}, {:ok, acc}) do
    case normalize_segment(segment) do
      {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
      {:error, _reason} -> {:halt, {:error, {:invalid_segment, index}}}
    end
  end

  defp finalize_normalized_segments({:ok, normalized}), do: {:ok, Enum.reverse(normalized)}
  defp finalize_normalized_segments(error), do: error

  defp normalize_segment(segment) when is_binary(segment) do
    normalized =
      segment
      |> String.trim()
      |> String.downcase()
      |> normalize_ref_segment([], false)

    if valid_ref_segment?(normalized) do
      {:ok, normalized}
    else
      {:error, :invalid_segment}
    end
  end

  defp normalize_segment(_segment), do: {:error, :invalid_segment}

  defp normalize_ref_segment(<<>>, acc, last_separator),
    do: finish_normalized(acc, last_separator)

  defp normalize_ref_segment(<<byte, rest::binary>>, acc, last_separator) do
    cond do
      ref_segment_byte?(byte) ->
        normalize_ref_segment(rest, [<<byte>> | acc], false)

      acc == [] ->
        normalize_ref_segment(rest, acc, true)

      last_separator ->
        normalize_ref_segment(rest, acc, true)

      true ->
        normalize_ref_segment(rest, ["_" | acc], true)
    end
  end

  defp finish_normalized(["_" | rest], true), do: rest |> Enum.reverse() |> IO.iodata_to_binary()
  defp finish_normalized(acc, _last_separator), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp valid_ref_segment?(<<>>), do: false

  defp valid_ref_segment?(<<first, rest::binary>>) do
    ascii_lower_or_digit?(first) and valid_ref_segment_rest?(rest)
  end

  defp valid_ref_segment_rest?(<<>>), do: true

  defp valid_ref_segment_rest?(<<byte, rest::binary>>) do
    ref_segment_byte?(byte) and valid_ref_segment_rest?(rest)
  end

  defp ref_segment_byte?(byte), do: ascii_lower_or_digit?(byte) or byte in [?_, ?-]
  defp ascii_lower_or_digit?(byte), do: byte in ?a..?z or byte in ?0..?9

  defp ref(scheme, segments), do: scheme <> "://" <> Enum.join(segments, "/")
end

defmodule GroundPlane.Contracts.ActorRef do
  @moduledoc "Opaque actor reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "actor", segments: 2
end

defmodule GroundPlane.Contracts.TenantRef do
  @moduledoc "Opaque tenant reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "tenant", segments: 1
end

defmodule GroundPlane.Contracts.InstallationRef do
  @moduledoc "Opaque installation reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "installation", segments: 3
end

defmodule GroundPlane.Contracts.TraceRef do
  @moduledoc "Opaque trace reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "trace", segments: 2
end

defmodule GroundPlane.Contracts.BindingRef do
  @moduledoc "Opaque binding reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "binding", segments: 4
end

defmodule GroundPlane.Contracts.OperationRef do
  @moduledoc "Opaque operation reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "operation", segments: 3
end

defmodule GroundPlane.Contracts.RevisionRef do
  @moduledoc "Opaque revision reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "revision", segments: 3
end

defmodule GroundPlane.Contracts.LeaseRef do
  @moduledoc "Opaque lease reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "lease", segments: 3
end

defmodule GroundPlane.Contracts.IdempotencyKey do
  @moduledoc "Opaque idempotency key."
  use GroundPlane.Contracts.OpaqueRef, scheme: "idempotency", segments: 2
end

defmodule GroundPlane.Contracts.CorrelationRef do
  @moduledoc "Opaque correlation reference."
  use GroundPlane.Contracts.OpaqueRef, scheme: "correlation", segments: 2
end
