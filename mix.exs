defmodule ExQuickbooks.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_quickbooks,
      version: version(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/ziyan-junaideen/ex_quickbooks"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_environment), do: ["lib"]

  defp description do
    "An Elixir client for the QuickBooks Online Accounting API."
  end

  defp docs do
    [
      main: "ExQuickBooks",
      extras: ["README.md"],
      source_ref: "v#{version()}",
      groups_for_modules: [
        "Core API": [
          ExQuickBooks,
          ExQuickBooks.Client,
          ExQuickBooks.Error
        ],
        Authentication: [
          ExQuickBooks.Auth,
          ExQuickBooks.Token
        ],
        Transport: [
          ExQuickBooks.Request,
          ExQuickBooks.HTTP,
          ExQuickBooks.Response
        ],
        Bootstrap: [
          ExQuickBooks.CompanyInfo,
          ExQuickBooks.Query,
          ExQuickBooks.CDC
        ],
        Resources: [
          ExQuickBooks.Customers,
          ExQuickBooks.Items,
          ExQuickBooks.Invoices,
          ExQuickBooks.Payments,
          ExQuickBooks.Accounts,
          ExQuickBooks.Vendors
        ]
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7.18", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5.10"},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "ex_quickbooks",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/ziyan-junaideen/ex_quickbooks",
        "HexDocs" => "https://hexdocs.pm/ex_quickbooks"
      }
    ]
  end

  defp version do
    "0.9.0"
  end
end
