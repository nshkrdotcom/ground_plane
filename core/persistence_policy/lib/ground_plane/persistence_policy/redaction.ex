defmodule GroundPlane.PersistencePolicy.Redaction do
  @moduledoc "Debug capture redaction constraints."

  @forbidden_keys [
    :raw_secret,
    :secret,
    :api_key,
    :oauth_secret,
    :token_file,
    :credential_body,
    :authorization_header,
    :auth_header,
    :raw_prompt,
    :prompt_body,
    :external_payload,
    :raw_external_payload,
    :resource_account_identifier,
    "raw_secret",
    "secret",
    "api_key",
    "oauth_secret",
    "token_file",
    "credential_body",
    "authorization_header",
    "auth_header",
    "raw_prompt",
    "prompt_body",
    "external_payload",
    "raw_external_payload",
    "resource_account_identifier"
  ]

  @spec forbidden_keys() :: [atom() | String.t()]
  def forbidden_keys, do: @forbidden_keys

  @spec validate_event(map()) :: :ok | {:error, term()}
  def validate_event(event) when is_map(event) do
    case Enum.find(@forbidden_keys, &has_key_deep?(event, &1)) do
      nil -> :ok
      key -> {:error, {:raw_debug_capture_forbidden, key}}
    end
  end

  def validate_event(_event), do: {:error, :invalid_debug_event}

  defp has_key_deep?(attrs, key) when is_map(attrs) do
    Map.has_key?(attrs, key) or Enum.any?(Map.values(attrs), &has_key_deep?(&1, key))
  end

  defp has_key_deep?(items, key) when is_list(items),
    do: Enum.any?(items, &has_key_deep?(&1, key))

  defp has_key_deep?(_value, _key), do: false
end
