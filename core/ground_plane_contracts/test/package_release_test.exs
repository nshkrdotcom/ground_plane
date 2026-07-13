defmodule GroundPlane.Contracts.PackageReleaseTest do
  use ExUnit.Case, async: true

  @required_files [
    ".formatter.exs",
    "CHANGELOG.md",
    "LICENSE",
    "README.md",
    "guides/installation.md",
    "guides/ownership.md"
  ]

  @forbidden_entries ~w(deps _build .git examples priv/plts credentials)

  test "project declares the public 0.1.0 package metadata" do
    project = Mix.Project.config()
    package = Keyword.fetch!(project, :package)

    assert project[:app] == :ground_plane_contracts
    assert project[:version] == "0.1.0"
    assert project[:elixir] == "~> 1.19"
    assert package[:name] == "ground_plane_contracts"
    assert package[:licenses] == ["MIT"]
    assert package[:maintainers] == ["nshkrdotcom"]

    assert package[:links] == %{
             "Changelog" =>
               "https://github.com/nshkrdotcom/ground_plane/blob/main/core/ground_plane_contracts/CHANGELOG.md",
             "GitHub" => "https://github.com/nshkrdotcom/ground_plane"
           }
  end

  test "package allowlist contains only package-owned release surfaces" do
    files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)

    assert files == ~w(.formatter.exs CHANGELOG.md LICENSE README.md guides lib mix.exs)
    assert Enum.all?(@forbidden_entries, &(&1 not in files))
    assert Enum.all?(@required_files, &File.regular?/1)
  end

  test "docs identify the release source and package guides" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)

    assert docs[:main] == "readme"
    assert docs[:source_ref] == "ground_plane_contracts-v0.1.0"
    assert docs[:source_url] == "https://github.com/nshkrdotcom/ground_plane"

    assert Enum.sort(docs[:extras]) ==
             Enum.sort([
               "README.md",
               "CHANGELOG.md",
               "LICENSE",
               "guides/installation.md",
               "guides/ownership.md"
             ])
  end
end
