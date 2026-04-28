defmodule GroundPlane.Contracts.RepoRef do
  @moduledoc """
  Generic repository reference for local workspaces and artifact ledgers.

  The reference carries source ownership only. It deliberately avoids product,
  provider, governance, execution-lane, and workflow semantics so it can sit in
  GroundPlane without pulling higher-layer meaning downward.
  """

  @ref_pattern ~r/^repo:\/\/[a-z0-9][a-z0-9_-]*\/[A-Za-z0-9][A-Za-z0-9_-]*$/
  @segment_pattern ~r/^[A-Za-z0-9][A-Za-z0-9_-]*$/

  @enforce_keys [:owner, :name, :ref]
  defstruct [:owner, :name, :ref]

  @type t :: %__MODULE__{
          owner: String.t(),
          name: String.t(),
          ref: String.t()
        }

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
         ref: "repo://#{normalized_owner}/#{normalized_name}"
       }}
    end
  end

  def new(_owner, _name), do: {:error, :invalid_repo_ref}

  @spec new!(String.t(), String.t()) :: t()
  def new!(owner, name) do
    case new(owner, name) do
      {:ok, repo_ref} -> repo_ref
      {:error, reason} -> raise ArgumentError, "invalid repo ref: #{inspect(reason)}"
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(value) when is_binary(value), do: String.match?(value, @ref_pattern)
  def valid?(_value), do: false

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse("repo://" <> rest = ref) when is_binary(ref) do
    case String.split(rest, "/", parts: 2) do
      [owner, name] ->
        with {:ok, repo_ref} <- new(owner, name),
             true <- repo_ref.ref == ref do
          {:ok, repo_ref}
        else
          false -> {:error, :non_canonical_repo_ref}
          error -> error
        end

      _parts ->
        {:error, :invalid_repo_ref}
    end
  end

  def parse(_ref), do: {:error, :invalid_repo_ref}

  defp normalize_owner(owner) do
    owner
    |> String.trim()
    |> String.downcase()
  end

  defp validate_segment(field, value) do
    if String.match?(value, @segment_pattern) do
      :ok
    else
      {:error, {:invalid_segment, field}}
    end
  end
end
