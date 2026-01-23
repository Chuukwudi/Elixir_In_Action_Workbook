defmodule Calculator do
  def divide(a, b) do
    # Check if both are numbers
    if is_number(a) and is_number(b) do
      if b != 0 do
        {:ok, a / b}
      else
        {:error, "Division by zero"}
      end
    else
      {:error, "Invalid input: both arguments must be numbers"}
    end
  end

  def safe_divide(a, b, default) do
    # Use divide/2 and return default on error
    case divide(a, b) do
      {:ok, result} -> result
      {:error, _reason} -> default
    end
  end
end


Calculator.divide(10, 2)                                                        # => {:ok, 5.0}
IO.puts("Result: #{inspect(Calculator.divide(10, 2))}")
Calculator.divide(10, 0)                                                        # => {:error, "Division by zero"}
IO.puts("Result: #{inspect(Calculator.divide(10, 0))}")
Calculator.divide(10, "2")                                                      # => {:error, "Arguments must be numbers"}
IO.puts("Result: #{inspect(Calculator.divide(10, "2"))}")
Calculator.safe_divide(10, 0, :infinity)                                        # => :infinity
IO.puts("Safe Result: #{inspect(Calculator.safe_divide(10, 0, :infinity))}")
