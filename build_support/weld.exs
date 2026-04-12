unless Code.ensure_loaded?(GroundPlane.Build.WeldContract) do
  Code.require_file("weld_contract.exs", __DIR__)
end

GroundPlane.Build.WeldContract.manifest()
