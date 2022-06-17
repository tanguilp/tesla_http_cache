defmodule TeslaHTTPCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_http_cache,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:http_cache, github: "tanguilp/http_cache"},
      {:telemetry, "~> 1.0"},
      {:tesla, "~> 1.4"}
    ]
  end
end
