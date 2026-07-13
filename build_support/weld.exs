Code.require_file("workspace_contract.exs", __DIR__)

defmodule GroundPlane.Build.WeldContract do
  @moduledoc false

  alias GroundPlane.Build.WorkspaceManifest

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
        project_globs: WorkspaceManifest.active_project_globs()
      ],
      classify: [
        tooling: ["."],
        proofs: ["examples/projection_smoke"]
      ],
      publication: [
        internal_only: [
          ".",
          "core/execution_fencing",
          "core/persistence_policy_data_extension",
          "examples/projection_smoke"
        ]
      ],
      artifacts: [
        ground_plane_contracts: contracts_artifact(),
        ground_plane_persistence_policy: persistence_policy_artifact()
      ]
    ]
  end

  def contracts_artifact do
    [
      roots: ["core/ground_plane_contracts"],
      package: [
        name: "ground_plane_contracts",
        otp_app: :ground_plane_contracts,
        version: "0.1.0",
        elixir: "~> 1.19",
        description: "Shared lower contract package projected from the GroundPlane workspace",
        licenses: ["MIT"],
        maintainers: ["nshkrdotcom"],
        links: %{"GitHub" => "https://github.com/nshkrdotcom/ground_plane"},
        docs_main: "readme"
      ],
      output: [
        docs: @artifact_docs,
        assets: ["CHANGELOG.md", "LICENSE"]
      ],
      verify: [
        artifact_tests: ["packaging/weld/ground_plane_contracts/test"],
        hex_build: true,
        hex_publish: true,
        smoke: [
          enabled: true,
          entry_file: "packaging/weld/ground_plane_contracts/smoke.ex"
        ]
      ]
    ]
  end

  def persistence_policy_artifact do
    [
      roots: ["core/persistence_policy"],
      package: [
        name: "ground_plane_persistence_policy",
        otp_app: :ground_plane_persistence_policy,
        version: "0.1.0",
        elixir: "~> 1.19",
        description: "Pure Ground Plane persistence policy contracts",
        licenses: ["MIT"],
        maintainers: ["nshkrdotcom"],
        links: %{"GitHub" => "https://github.com/nshkrdotcom/ground_plane"},
        docs_main: "readme"
      ],
      output: [
        docs: ["README.md"],
        assets: ["CHANGELOG.md", "LICENSE"]
      ],
      verify: [
        artifact_tests: ["packaging/weld/ground_plane_persistence_policy/test"],
        hex_build: true,
        hex_publish: true,
        smoke: [
          enabled: true,
          entry_file: "packaging/weld/ground_plane_persistence_policy/smoke.ex"
        ]
      ]
    ]
  end
end

GroundPlane.Build.WeldContract.manifest()
