defmodule Socrates.MixProject do
  use Mix.Project

  def project do
    [
      app: :socrates,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: [{:req, "~> 0.5"}],
      escript: [main_module: Socrates.CLI]
    ]
  end

  def application do
    [extra_applications: [:crypto, :public_key, :logger]]
  end
end
