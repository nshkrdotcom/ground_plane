defmodule GroundPlaneContracts.MixProject do
  use Mix.Project

  def project do
    [
      app: :ground_plane_contracts,
      version: "0.1.0",
      build_path: "_build",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      erlc_paths: ["components/core/ground_plane_contracts/src"],
      deps: deps(),
      description: "Shared lower contract package projected from the GroundPlane workspace",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:crypto, :logger]]
  end

  def elixirc_paths(:test) do
    base = ["config", "components/core/ground_plane_contracts/lib"]

    if File.dir?("test/support") do
      base ++ ["test/support"]
    else
      base
    end
  end

  def elixirc_paths(_env), do: ["config", "components/core/ground_plane_contracts/lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.40", [only: :dev, runtime: false]}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: [],
      links: %{"Source" => "https://github.com/nshkrdotcom/ground_plane"},
      files: [
        ".formatter.exs",
        "CHANGELOG.md",
        "LICENSE",
        "README.md",
        "components/core/ground_plane_contracts",
        "config",
        "docs/contracts.md",
        "docs/overview.md",
        "docs/postgres_helpers.md",
        "docs/projection.md",
        "mix.exs",
        "projection.lock.json"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/contracts.md",
        "docs/overview.md",
        "docs/postgres_helpers.md",
        "docs/projection.md"
      ]
    ]
  end
end
