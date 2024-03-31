defmodule Reminder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReminderWeb.Telemetry,
      Reminder.Repo,
      {DNSCluster, query: Application.get_env(:reminder, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Reminder.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Reminder.Finch},
      # Start a worker by calling: Reminder.Worker.start_link(arg)
      # {Reminder.Worker, arg},
      # Start to serve requests, typically the last entry
      ReminderWeb.Endpoint,
      {Oban, Application.fetch_env!(:reminder, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Reminder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReminderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
