defmodule Rule do
  def number(n) do
    IO.puts("\n #{String.duplicate("-", 50)} Exercise #{String.pad_leading("#{n}", 2, "0")} #{String.duplicate("-", 50)}\n")
  end
end

# Exercise 01: Data Pipeline with Pipe Operator
Rule.number(1)

defmodule DataPipeline do
  def parse_csv_line(line) do
    [name, age, job] = String.split(line, ",") |> Enum.map(&String.trim/1)
    %{
      name: name,
      age: String.to_integer(age),
      job: job
    }
  end

  def validate_age(map) do
    if map.age >= 18 do
      map
    else
      %{error: "Too young"}
    end
  end

  def normalize_name(%{error: _} = error), do: error
  def normalize_name(map) do
    Map.update!(map, :name, &String.capitalize/1)
  end

  def normalize_job(%{error: _} = error), do: error
  def normalize_job(map) do
    Map.update!(map, :job, &String.capitalize/1)
  end

  def format_output(%{error: reason}), do: "Error: #{reason}"
  def format_output(map) do
    "Name: #{map.name}, Age: #{map.age}, Job: #{map.job}"
  end

  def process(line) do
    line
    |> parse_csv_line()
    |> validate_age()
    |> normalize_name()
    |> normalize_job()
    |> format_output()
  end

end


csv_line = "alice,30,Engineer"
parsed_data = DataPipeline.parse_csv_line(csv_line)
IO.inspect(parsed_data, label: "Parsed Data")

validated_data = DataPipeline.validate_age(parsed_data)
IO.inspect(validated_data, label: "Validated Data")

normalized_data = DataPipeline.normalize_name(validated_data)
IO.inspect(normalized_data, label: "Normalized Data")

normalized_job_data = DataPipeline.normalize_job(normalized_data)
IO.inspect(normalized_job_data, label: "Normalized Job Data")

formatted_output = DataPipeline.format_output(normalized_job_data)
IO.puts("Formatted Output: #{formatted_output}")

all = csv_line
|> DataPipeline.parse_csv_line()
|> DataPipeline.validate_age()
|> DataPipeline.normalize_name()
|> DataPipeline.normalize_job()
|> DataPipeline.format_output()

IO.puts("All in one pipeline: #{all}")

IO.puts("Here is the Processed Output: #{DataPipeline.process(csv_line)}")


# Timing the process function
{process_time, result} = :timer.tc(fn ->
  DataPipeline.process(csv_line)
end)

IO.puts("Here is the Processed Output: #{result}")
IO.puts("Process function took: #{process_time} microseconds (#{process_time / 1000} ms)")
