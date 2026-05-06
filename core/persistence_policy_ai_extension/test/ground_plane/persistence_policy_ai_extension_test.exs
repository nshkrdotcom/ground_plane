defmodule GroundPlane.PersistencePolicyAIExtensionTest do
  use ExUnit.Case, async: true

  alias GroundPlane.PersistencePolicyAIExtension
  alias GroundPlane.PersistencePolicyAIExtension.Capability

  test "all AI data classes default to memory" do
    profile = PersistencePolicyAIExtension.memory_default_profile()

    for data_class <- PersistencePolicyAIExtension.data_classes() do
      assert :ok =
               PersistencePolicyAIExtension.preflight(profile, data_class, :memory_ephemeral, [])

      assert profile.data_classes[data_class].default_tier == :memory_ephemeral
    end
  end

  test "durable selection fails early without a registered capability" do
    profile = PersistencePolicyAIExtension.memory_default_profile()

    assert {:error, {:missing_durable_ai_store_capability, :memory_episodic, :postgres_shared}} =
             PersistencePolicyAIExtension.preflight(
               profile,
               :memory_episodic,
               :postgres_shared,
               []
             )
  end

  test "durable selection passes with explicit capability" do
    profile = PersistencePolicyAIExtension.memory_default_profile()

    assert :ok =
             PersistencePolicyAIExtension.preflight(profile, :memory_episodic, :postgres_shared, [
               %Capability{
                 data_class: :memory_episodic,
                 tier: :postgres_shared,
                 adapter: :memory_postgres
               }
             ])
  end

  test "unsupported data classes and tiers fail closed" do
    profile = PersistencePolicyAIExtension.memory_default_profile()

    assert {:error, {:unknown_ai_data_class, :unknown}} =
             PersistencePolicyAIExtension.preflight(profile, :unknown, :memory_ephemeral, [])

    assert {:error, {:unsupported_ai_persistence_tier, :hive_message, :vector_claim_check}} =
             PersistencePolicyAIExtension.preflight(
               profile,
               :hive_message,
               :vector_claim_check,
               []
             )
  end
end
