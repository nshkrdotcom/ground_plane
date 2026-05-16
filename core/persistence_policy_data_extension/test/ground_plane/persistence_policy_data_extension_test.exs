defmodule GroundPlane.PersistencePolicyDataExtensionTest do
  use ExUnit.Case, async: true

  alias GroundPlane.PersistencePolicyDataExtension
  alias GroundPlane.PersistencePolicyDataExtension.Capability

  test "all data classes default to memory" do
    profile = PersistencePolicyDataExtension.memory_default_profile()

    for data_class <- PersistencePolicyDataExtension.data_classes() do
      assert :ok =
               PersistencePolicyDataExtension.preflight(
                 profile,
                 data_class,
                 :memory_ephemeral,
                 []
               )

      assert profile.data_classes[data_class].default_tier == :memory_ephemeral
    end
  end

  test "durable selection fails early without a registered capability" do
    profile = PersistencePolicyDataExtension.memory_default_profile()

    assert {:error, {:missing_durable_store_capability, :cache_entry, :postgres_shared}} =
             PersistencePolicyDataExtension.preflight(
               profile,
               :cache_entry,
               :postgres_shared,
               []
             )
  end

  test "durable selection passes with explicit capability" do
    profile = PersistencePolicyDataExtension.memory_default_profile()

    assert :ok =
             PersistencePolicyDataExtension.preflight(profile, :cache_entry, :postgres_shared, [
               %Capability{
                 data_class: :cache_entry,
                 tier: :postgres_shared,
                 adapter: :memory_postgres
               }
             ])
  end

  test "unsupported data classes and tiers fail closed" do
    profile = PersistencePolicyDataExtension.memory_default_profile()

    assert {:error, {:unknown_data_class, :unknown}} =
             PersistencePolicyDataExtension.preflight(profile, :unknown, :memory_ephemeral, [])

    assert {:error, {:unsupported_data_persistence_tier, :message_record, :vector_claim_check}} =
             PersistencePolicyDataExtension.preflight(
               profile,
               :message_record,
               :vector_claim_check,
               []
             )
  end
end
