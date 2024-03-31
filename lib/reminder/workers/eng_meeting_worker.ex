defmodule Reminder.Workers.EngMeeting do
  use Oban.Worker, queue: :eng_meeting

  alias Reminder.Job
  @impl Oban.Worker

  def perform(_job) do
    Job.fetch_schedule()
    :ok
  end
end
