defmodule GroundPlane.Contracts.PackageReleaseTest do
  use ExUnit.Case, async: true

  @required_files [
    ".formatter.exs",
    "CHANGELOG.md",
    "LICENSE",
    "README.md",
    "assets/ground_plane_contracts.svg",
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

    assert files == ~w(.formatter.exs CHANGELOG.md LICENSE README.md assets guides lib mix.exs)
    assert Enum.all?(@forbidden_entries, &(&1 not in files))
    assert Enum.all?(@required_files, &File.regular?/1)
  end

  test "docs identify the release source and package guides" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)

    assert docs[:main] == "readme"
    assert docs[:source_ref] == "ground_plane_contracts-v0.1.0"
    assert docs[:source_url] == "https://github.com/nshkrdotcom/ground_plane"
    assert docs[:logo] == "assets/ground_plane_contracts.svg"
    assert docs[:assets] == %{"assets" => "assets"}

    assert docs[:groups_for_extras] == [
             Overview: ["README.md"],
             Guides: ["guides/installation.md", "guides/ownership.md"],
             Release: ["CHANGELOG.md", "LICENSE"]
           ]

    assert Enum.sort(docs[:extras]) ==
             Enum.sort([
               "README.md",
               "CHANGELOG.md",
               "LICENSE",
               "guides/installation.md",
               "guides/ownership.md"
             ])
  end

  test "release presentation is package-local and branded" do
    readme = File.read!("README.md")
    license = File.read!("LICENSE")
    changelog = File.read!("CHANGELOG.md")
    logo = File.read!("assets/ground_plane_contracts.svg")

    assert readme =~ ~s(src="assets/ground_plane_contracts.svg")
    assert readme =~ ~s(width="200" height="200")
    assert readme =~ "https://github.com/nshkrdotcom/ground_plane"
    assert readme =~ "license-MIT"
    assert license =~ "Copyright (c) 2026 nshkrdotcom"
    assert changelog == "# Changelog\n\n## 0.1.0 - 2026-07-13\n\n- Initial release.\n"
    assert logo =~ ~s(viewBox="0 0 200 200")
    assert logo =~ ~s(width="200" height="200")
  end
end
