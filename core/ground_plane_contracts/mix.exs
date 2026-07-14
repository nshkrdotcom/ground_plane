defmodule GroundPlane.Contracts.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/ground_plane"

  def project do
    [
      app: :ground_plane_contracts,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: dialyzer(),
      name: "GroundPlane Contracts",
      description: "Pure shared lower contracts for the GroundPlane workspace",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        dialyzer: :test
      ]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "ground_plane_contracts-v#{@version}",
      source_url: @source_url,
      logo: "assets/ground_plane_contracts.svg",
      assets: %{"assets" => "assets"},
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/installation.md",
        "guides/ownership.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Guides: ["guides/installation.md", "guides/ownership.md"],
        Release: ["CHANGELOG.md", "LICENSE"]
      ]
    ]
  end

  defp package do
    [
      name: "ground_plane_contracts",
      licenses: ["MIT"],
      maintainers: ["nshkrdotcom"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/core/ground_plane_contracts/CHANGELOG.md"
      },
      files: ~w(.formatter.exs CHANGELOG.md LICENSE README.md assets guides lib mix.exs)
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct
    ]
  end
end
