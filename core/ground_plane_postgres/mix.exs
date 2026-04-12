defmodule GroundPlane.Postgres.MixProject do
  use Mix.Project

  def project do
    [
      app: :ground_plane_postgres,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer(),
      name: "GroundPlane Postgres",
      description: "Generic lower Postgres helpers for the GroundPlane workspace"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
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
      {:ground_plane_contracts, path: "../ground_plane_contracts"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct
    ]
  end
end
