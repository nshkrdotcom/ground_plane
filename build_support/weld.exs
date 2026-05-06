Code.require_file("workspace_contract.exs", __DIR__)

defmodule GroundPlane.Build.WeldContract do
  @moduledoc false

  @artifact_docs [
    "README.md",
    "docs/overview.md",
    "docs/contracts.md",
    "docs/postgres_helpers.md",
    "docs/projection.md"
  ]

  def manifest do
    [
      workspace: [
        root: "..",
        project_globs: GroundPlane.Build.WorkspaceManifest.active_project_globs()
      ],
      classify: [
        tooling: ["."],
        proofs: ["examples/projection_smoke"]
      ],
      publication: [
        internal_only: [".", "core/persistence_policy_ai_extension", "examples/projection_smoke"]
      ],
      artifacts: [
        ground_plane_contracts: artifact()
      ]
    ]
  end

  def artifact do
    [
      roots: ["core/ground_plane_contracts"],
      package: [
        name: "ground_plane_contracts",
        otp_app: :ground_plane_contracts,
        version: "0.1.0",
        description: "Shared lower contract package projected from the GroundPlane workspace"
      ],
      output: [
        docs: @artifact_docs,
        assets: ["CHANGELOG.md", "LICENSE"]
      ],
      verify: [
        artifact_tests: ["packaging/weld/ground_plane_contracts/test"],
        hex_build: false,
        hex_publish: false
      ]
    ]
  end
end

GroundPlane.Build.WeldContract.manifest()
