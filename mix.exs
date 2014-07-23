defmodule Abort.Mixfile do
  use Mix.Project

  def project do
    [app: :plug_abort,
     version: "0.0.5",
     elixir: "~> 0.14.2",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: []]
  end

  defp deps do
    [{:cowboy, github: "extend/cowboy"},
     {:plug, "~> 0.5.1"},
     {:jazz, "~> 0.1.2"}]
  end
end
