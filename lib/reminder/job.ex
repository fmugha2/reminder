defmodule Reminder.Job do
  @moduledoc false

  @special_names ["Daniel Andrews", "Laura Eble", "Luke Ledet", "Nick Schello"]

  def fetch_schedule do
    {data, _count} =
      System.cmd("curl", [
        "-s",
        "-H",
        "Authorization: token #{Application.get_env(:reminder, :github_token)}",
        "https://raw.githubusercontent.com/revelrylabs/engineering/main/meeting/README.md"
      ])

    [content, type] = handle_schedule_data(data)
    build_and_send(content, type)
  end

  defp handle_schedule_data("404: Not Found"),
    do: ["Unable to reach Revelry repo, please fix.", :message]

  # parse the schedule using next week's meeting date
  defp handle_schedule_data(schedule) when is_binary(schedule) do
    date =
      Date.utc_today()
      |> Date.add(7)
      |> Date.to_iso8601()

    match = Regex.scan(~r/\[#{date} - (.*?)\]/, schedule)

    [match, :user]
  end

  # didn't find any matches for next week, need to update the schedule
  defp build_and_send([], :user), do: send_slack_message("Time to reroll the schedule!")

  # send a generic message if it is a FREE meeting, otherwise notify the user
  defp build_and_send(match, :user) do
    presenter = Enum.at(Enum.at(match, 0), 1)

    if presenter == "FREE" do
      send_slack_message("Next week is a FREE meeting!")
    else
      presenter |> build_email_address() |> send_slack_reminder()
    end
  end

  defp build_and_send(message, :message), do: send_slack_message(message)

  # some OGs got "firstname@reverly.co"
  defp build_email_address(name) when name in @special_names do
    [first_name | _rest] = String.split(name)
    "#{String.downcase(first_name)}@revelry.co"
  end

  # Bob is also special
  defp build_email_address("Bob Weilbaecher"), do: "robert.weilbaecher@revelry.co"

  defp build_email_address(name) do
    [first_name, last_name] = String.split(name)
    "#{String.downcase(first_name)}.#{String.downcase(last_name)}@revelry.co"
  end

  # ====== SEND DATA TO SLACK ======

  # slack webhooks don't accept optional variables, so we have 2 urls for tagging someone or just generic messages
  defp send_slack_message(data) do
    payload = ~s({"message": "#{data}"})
    IO.inspect(payload, label: "payload")

    System.cmd("curl", [
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-d",
      payload,
      Application.get_env(:reminder, :slack)[:message_webhook_url]
    ])
  end

  defp send_slack_reminder(data) do
    payload = ~s({"user": "#{data}"})

    System.cmd("curl", [
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-d",
      payload,
      Application.get_env(:reminder, :slack)[:user_webhook_url]
    ])
  end
end
