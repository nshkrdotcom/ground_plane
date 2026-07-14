defmodule GroundPlane.PersistencePolicy.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nshkrdotcom/ground_plane"

  def project do
    [
      app: :ground_plane_persistence_policy,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: [plt_add_deps: :apps_direct],
      name: "GroundPlane Persistence Policy",
      description: "Pure persistence profile, tier, capture, store, and debug contract",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "ground_plane_persistence_policy-v#{@version}",
      source_url: @source_url,
      logo: "assets/ground_plane_persistence_policy.svg",
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
      name: "ground_plane_persistence_policy",
      licenses: ["MIT"],
      maintainers: ["nshkrdotcom"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/core/persistence_policy/CHANGELOG.md"
      },
      files: ~w(.formatter.exs CHANGELOG.md LICENSE README.md assets guides lib mix.exs)
    ]
  end
end
