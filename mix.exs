defmodule TeslaHTTPCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_http_cache,
      description: "HTTP caching middleware for Tesla",
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      package: package(),
      source_url: "https://github.com/tanguilp/tesla_http_cache"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:http_cache, "~> 0.2"},
      {:telemetry, "~> 1.0"},
      {:tesla, "~> 1.4"}
    ]
  end

  def package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/tanguilp/tesla_http_cache"}
    ]
  end
end
