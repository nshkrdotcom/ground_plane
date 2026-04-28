defmodule GroundPlane.Contracts.ArtifactRef do
  @moduledoc """
  Opaque artifact reference for contract ledgers and proof receipts.

  The reference identifies a produced artifact by owner, producer repository,
  and artifact name only. It deliberately carries no release, audit,
  provider, product, or workflow semantics.
  """

  @ref_pattern ~r/^artifact:\/\/[a-z0-9][a-z0-9_-]*\/[A-Za-z0-9][A-Za-z0-9_-]*\/[A-Za-z0-9][A-Za-z0-9_.-]*$/
  @segment_pattern ~r/^[A-Za-z0-9][A-Za-z0-9_.-]*$/

  @enforce_keys [:owner, :repo, :name, :ref]
  defstruct [:owner, :repo, :name, :ref]

  @type t :: %__MODULE__{
          owner: String.t(),
          repo: String.t(),
          name: String.t(),
          ref: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with {:ok, owner} <- fetch_string(attrs, :owner),
         {:ok, repo} <- fetch_string(attrs, :repo),
         {:ok, name} <- fetch_string(attrs, :name) do
      new(owner, repo, name)
    end
  end

  def new(_attrs), do: {:error, :invalid_artifact_ref}

  @spec new(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def new(owner, repo, name) when is_binary(owner) and is_binary(repo) and is_binary(name) do
    normalized_owner = normalize_owner(owner)
    normalized_repo = String.trim(repo)
    normalized_name = String.trim(name)

    with :ok <- validate_segment(:owner, normalized_owner),
         :ok <- validate_segment(:repo, normalized_repo),
         :ok <- validate_segment(:name, normalized_name) do
      {:ok,
       %__MODULE__{
         owner: normalized_owner,
         repo: normalized_repo,
         name: normalized_name,
         ref: "artifact://#{normalized_owner}/#{normalized_repo}/#{normalized_name}"
       }}
    end
  end

  def new(_owner, _repo, _name), do: {:error, :invalid_artifact_ref}

  @spec new!(String.t(), String.t(), String.t()) :: t()
  def new!(owner, repo, name) do
    case new(owner, repo, name) do
      {:ok, artifact_ref} -> artifact_ref
      {:error, reason} -> raise ArgumentError, "invalid artifact ref: #{inspect(reason)}"
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(value) when is_binary(value), do: String.match?(value, @ref_pattern)
  def valid?(_value), do: false

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse("artifact://" <> rest = ref) when is_binary(ref) do
    case String.split(rest, "/", parts: 3) do
      [owner, repo, name] ->
        with {:ok, artifact_ref} <- new(owner, repo, name),
             true <- artifact_ref.ref == ref do
          {:ok, artifact_ref}
        else
          false -> {:error, :non_canonical_artifact_ref}
          error -> error
        end

      _parts ->
        {:error, :invalid_artifact_ref}
    end
  end

  def parse(_ref), do: {:error, :invalid_artifact_ref}

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
      _other -> {:error, :invalid_artifact_ref}
    end
  end

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
