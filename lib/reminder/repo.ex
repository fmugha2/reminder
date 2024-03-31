defmodule Reminder.Repo do
  use Ecto.Repo,
    otp_app: :reminder,
    adapter: Ecto.Adapters.Postgres
end
