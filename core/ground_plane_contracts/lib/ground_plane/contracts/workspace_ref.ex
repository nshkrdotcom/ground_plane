defmodule GroundPlane.Contracts.WorkspaceRef do
  @moduledoc """
  Opaque workspace reference for manifests, proof ledgers, and trace fixtures.

  The reference identifies a logical workspace by owner and workspace name
  only. It does not contain local filesystem paths, tenant policy, product
  semantics, provider payloads, or runtime execution details.
  """

  alias GroundPlane.Contracts.Segment

  @enforce_keys [:owner, :name, :ref]
  defstruct [:owner, :name, :ref]

  @type t :: %__MODULE__{
          owner: String.t(),
          name: String.t(),
          ref: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with {:ok, owner} <- fetch_string(attrs, :owner),
         {:ok, name} <- fetch_string(attrs, :name) do
      new(owner, name)
    end
  end

  def new(_attrs), do: {:error, :invalid_workspace_ref}

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def new(owner, name) when is_binary(owner) and is_binary(name) do
    normalized_owner = normalize_owner(owner)
    normalized_name = String.trim(name)

    with :ok <- validate_segment(:owner, normalized_owner),
         :ok <- validate_segment(:name, normalized_name) do
      {:ok,
       %__MODULE__{
         owner: normalized_owner,
         name: normalized_name,
         ref: "workspace://#{normalized_owner}/#{normalized_name}"
       }}
    end
  end

  def new(_owner, _name), do: {:error, :invalid_workspace_ref}

  @spec new!(String.t(), String.t()) :: t()
  def new!(owner, name) do
    case new(owner, name) do
      {:ok, workspace_ref} -> workspace_ref
      {:error, reason} -> raise ArgumentError, "invalid workspace ref: #{inspect(reason)}"
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(value) when is_binary(value) do
    case parse(value) do
      {:ok, _workspace_ref} -> true
      {:error, _reason} -> false
    end
  end

  def valid?(_value), do: false

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse("workspace://" <> rest = ref) when is_binary(ref) do
    case String.split(rest, "/", parts: 2) do
      [owner, name] ->
        with {:ok, workspace_ref} <- new(owner, name),
             true <- workspace_ref.ref == ref do
          {:ok, workspace_ref}
        else
          false -> {:error, :non_canonical_workspace_ref}
          error -> error
        end

      _parts ->
        {:error, :invalid_workspace_ref}
    end
  end

  def parse(_ref), do: {:error, :invalid_workspace_ref}

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{ref: ref}), do: ref

  defp fetch_string(attrs, field) when is_atom(field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      :error -> fetch_string(attrs, Atom.to_string(field))
      _other -> {:error, {:invalid_segment, field}}
    end
  end

  defp fetch_string(attrs, field) when is_binary(field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      _other -> {:error, :invalid_workspace_ref}
    end
  end

  defp normalize_owner(owner) do
    owner
    |> String.trim()
    |> String.downcase()
  end

  defp validate_segment(field, value) do
    if valid_segment?(field, value) do
      :ok
    else
      {:error, {:invalid_segment, field}}
    end
  end

  defp valid_segment?(:owner, value), do: Segment.owner?(value)
  defp valid_segment?(:name, value), do: Segment.name?(value)
end
