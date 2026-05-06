defmodule GroundPlane.AIRunFencing.Validation do
  @moduledoc false

  @spec require_non_empty_refs(map(), [atom()]) :: :ok | {:error, {atom(), map()}}
  def require_non_empty_refs(attrs, fields) when is_map(attrs) and is_list(fields) do
    missing =
      Enum.reject(fields, fn field ->
        case Map.get(attrs, field, Map.get(attrs, Atom.to_string(field))) do
          value when is_binary(value) -> String.trim(value) != ""
          _other -> false
        end
      end)

    case missing do
      [] -> :ok
      _ -> {:error, {:missing_required_refs, %{missing: missing, redacted: true}}}
    end
  end

  @spec fetch_string!(map(), atom()) :: String.t()
  def fetch_string!(attrs, field) when is_map(attrs) and is_atom(field) do
    Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
  end

  @spec fetch_map!(map(), atom()) :: map()
  def fetch_map!(attrs, field) when is_map(attrs) and is_atom(field) do
    case Map.get(attrs, field, Map.get(attrs, Atom.to_string(field))) do
      value when is_map(value) -> value
      _other -> %{}
    end
  end

  @spec fetch_datetime(map(), atom()) :: {:ok, DateTime.t()} | {:error, {atom(), map()}}
  def fetch_datetime(attrs, field) when is_map(attrs) and is_atom(field) do
    case Map.get(attrs, field, Map.get(attrs, Atom.to_string(field))) do
      %DateTime{} = value -> {:ok, value}
      _other -> {:error, {:invalid_datetime, %{field: field, redacted: true}}}
    end
  end

  @spec fetch_non_negative_integer(map(), atom()) ::
          {:ok, non_neg_integer()} | {:error, {atom(), map()}}
  def fetch_non_negative_integer(attrs, field) when is_map(attrs) and is_atom(field) do
    case Map.get(attrs, field, Map.get(attrs, Atom.to_string(field))) do
      value when is_integer(value) and value >= 0 ->
        {:ok, value}

      _other ->
        {:error, {:invalid_non_negative_integer, %{field: field, redacted: true}}}
    end
  end
end
