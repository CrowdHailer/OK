defmodule OK.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ok,
      version: "1.9.4",
      elixir: "~> 1.1",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: [
        main: "readme",
        source_url: "https://github.com/CrowdHailer/OK",
        extras: ["README.md"]
      ],
      package: package()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Elegant error/exception handling in Elixir, with result monads.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Peter Saxton"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/CrowdHailer/OK"}
    ]
  end
end
