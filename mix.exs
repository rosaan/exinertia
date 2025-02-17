defmodule Exinertia.MixProject do
  use Mix.Project

  def project do
    [
      app: :exinertia,
      version: "0.8.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description:
        "A toolkit for seamlessly integrating Inertia.js with Phoenix, using Bun for JavaScript and CSS bundling",
      package: package(),
      source_url: "https://github.com/nordbeam/exinertia",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.5", optional: true},
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Assim El Hammouti"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nordbeam/exinertia"},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md)
    ]
  end
end
