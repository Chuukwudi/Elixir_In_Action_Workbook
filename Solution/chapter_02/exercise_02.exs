defmodule Rule do
  def number(n) do
    IO.puts("\n #{String.duplicate("-", 50)} Exercise #{String.pad_leading("#{n}", 2, "0")} #{String.duplicate("-", 50)}\n")
  end
end

# Exercise 2: Keyword Lists for Configuration
Rule.number(2)

defmodule MyLogger do
  def log(message, opts \\ []) do
    level = Keyword.get(opts, :level, :info)
    timestamp = Keyword.get(opts, :timestamp, true)
    prefix = Keyword.get(opts, :prefix, "")
    formatted_message = format(message, level, timestamp, prefix)
    IO.puts(formatted_message)
  end

  defp format(message, level, timestamp, prefix) do
    time_str = if timestamp do
      {{year, month, day}, {hour, minute, second}} = :calendar.local_time()
      "[#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}]"
    else
      ""
    end

    "#{time_str} #{String.upcase(to_string(level))} #{prefix} #{message}"
  end
end

MyLogger.log("System started")
MyLogger.log("Debug info", level: :debug, prefix: "[APP]")
MyLogger.log("Error occurred", level: :error, timestamp: false)
MyLogger.log("Custom log", level: :warn, timestamp: true, prefix: "[CUSTOM]")
