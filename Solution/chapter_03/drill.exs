defmodule Rule do
  def number(n) do
    IO.puts("\n #{String.duplicate("-", 50)} Exercise #{String.pad_leading("#{n}", 2, "0")} #{String.duplicate("-", 50)}\n")
  end
end

# Drill 1: Basic Pattern Matching
Rule.number(1)

# These were tested via the console.
# 1
{a, b} = {1, 2}                                           # a = 1, b = 2

# 2
# {a, b, c} = {1, 2}                                        # Match error


# 3
[head | tail] = [1, 2, 3]                                 # head = 1, tail = [2, 3]

# 4
# [head | tail] = []                                        # Match error

# 5
{:ok, result} = {:ok, 42}                                 # result = 42

# 6
# {:ok, result} = {:error, "failed"}                        # Match error

# 7
%{name: name} = %{name: "Alice", age: 30}                 # name = "Alice"

# 8
# %{name: name, job: job} = %{name: "Alice", age: 30}       # Match error

# 9
[a, a] = [5, 5]                                           # a = 5

# 10
# [a, a] = [5, 6]                                           # Match error



# Drill 2: Destructuring Complex Data
Rule.number(2)

profile = %{
  user: %{name: "Alice", age: 30},
  address: %{street: "123 Main St", city: "Portland"},
  contacts: [
    {:email, "alice@example.com"},
    {:phone, "555-1234"}
  ]
}

%{user: %{name: name}} = profile
IO.puts("Name: #{name}")

%{address: %{city: city}, contacts: [email_tuple | _]} = profile
IO.puts("City: #{city}")
IO.inspect(email_tuple, label: "First Contact tuple")

%{contacts: [_, {:phone, phone_number}]} = profile
IO.puts("Phone Number: #{phone_number}")


# Drill 3: Multiclause Functions
Rule.number(3)

defmodule Geometry do
  # Implement area/1 for:
  # {:rectangle, width, height}
  def area({:rectangle, width, height}) do
    width * height
  end

  # {:square, side}
  def area({:square, side}) do
    side * side
  end

  # {:circle, radius}
  def area({:circle, radius}) do
    :math.pi() * radius * radius
  end

  # {:triangle, base, height}
  def area({:triangle, base, height}) do
    0.5 * base * height
  end

  # Any other shape should return {:error, :unknown_shape}
  def area(_) do
    {:error, :unknown_shape}
  end
end

IO.puts("Geometry.area({:rectangle, 4, 5}) = #{Geometry.area({:rectangle, 4, 5})}")  # => 20
IO.puts("Geometry.area({:square, 5})       = #{Geometry.area({:square, 5})}")        # => 25
IO.puts("Geometry.area({:circle, 3})       = #{Geometry.area({:circle, 3})}")        # => 28.26 (approx, use 3.14 for pi)
IO.puts("Geometry.area({:triangle, 6, 4})  = #{Geometry.area({:triangle, 6, 4})}")   # => 12.0
IO.puts("Geometry.area({:hexagon, 5})      = #{inspect(Geometry.area({:hexagon, 5}))}")       # => {:error, :unknown_shape}


# Drill 4: Guards in Action
Rule.number(4)

defmodule NumberClassifier do
  # classify/1 - returns :positive, :negative, or :zero
  # Only accepts numbers; raises FunctionClauseError for non-numbers
  def classify(n) when is_number(n) and n > 0 do
    :positive
  end
  def classify(n) when is_number(n) and n < 0 do
    :negative
  end
  def classify(n) when not is_number(n) do
    FunctionClauseError
  end
  def classify(0) do
    :zero
  end


  # fizzbuzz/1 - returns:
  #   "FizzBuzz" if divisible by both 3 and 5
  #   "Fizz" if divisible by 3
  #   "Buzz" if divisible by 5
  #   The number itself (as string) otherwise
  # Only works for integers

  def fizzbuzz(n) do
    cond do
      is_integer(n) and rem(n, 15) == 0 -> "FizzBuzz"
      is_integer(n) and rem(n, 3) == 0 -> "Fizz"
      is_integer(n) and rem(n, 5) == 0 -> "Buzz"
      is_integer(n) -> Integer.to_string(n)
      true -> raise FunctionClauseError
    end
  end
end

IO.puts("NumberClassifier.classify(5)  = #{inspect(NumberClassifier.classify(5))}")   # => :positive
IO.puts("NumberClassifier.classify(-3) = #{inspect(NumberClassifier.classify(-3))}")  # => :negative
IO.puts("NumberClassifier.classify(0)  = #{inspect(NumberClassifier.classify(0))}")   # => :zero
IO.puts("NumberClassifier.classify(:x) = #{inspect(NumberClassifier.classify(:x))}")  # => FunctionClauseError

IO.puts("NumberClassifier.fizzbuzz(15) = #{inspect(NumberClassifier.fizzbuzz(15))}")  # => "FizzBuzz"
IO.puts("NumberClassifier.fizzbuzz(9)  = #{inspect(NumberClassifier.fizzbuzz(9))}")   # => "Fizz"
IO.puts("NumberClassifier.fizzbuzz(10) = #{inspect(NumberClassifier.fizzbuzz(10))}")  # => "Buzz"
IO.puts("NumberClassifier.fizzbuzz(7)  = #{inspect(NumberClassifier.fizzbuzz(7))}")   # => "7"



# Drill 5: Recursion Basics
Rule.number(5)

defmodule RecursionPractice do
  # countdown/1 - prints numbers from n down to 1
  def countdown(0), do: IO.puts("0")
  def countdown(n) do
    # Your implementation
    IO.puts(n)
    countdown(n - 1)
  end

  # list_length/1 - calculates length of a list recursively
  def list_length([]), do: 0
  def list_length(list) do
    # Your implementation
    [ _head | tail] = list
    1 + list_length(tail)
  end

  # range/2 - creates a list of numbers from `from` to `to`
  # e.g., range(3, 7) => [3, 4, 5, 6, 7]
  def range(from, to) when from == to do
    [to]
  end
  def range(from, to) do
    # Your implementation
    [ from | range( from + 1, to )]
  end
end

IO.puts("RecursionPractice.countdown(5):")
RecursionPractice.countdown(5)  # Should print 5, 4, 3, 2, 1

IO.puts(("RecursionPractice.list_length([1, 2, 3, 4, 5, 6, 7, 0]):"))
IO.puts(RecursionPractice.list_length([1, 2, 3, 4, 5, 6, 7, 0]))

IO.inspect(RecursionPractice.range(3, 7), label: "RecursionPractice.range(3, 7)")


# Drill 6: Tail Recursion
Rule.number(6)

defmodule TailRecursion do
  # Tail-recursive list_length
  def list_length(list) do
    do_length(list, 0)
  end

  defp do_length([], acc), do: acc
  defp do_length([_ | tail], acc), do: do_length(tail, acc + 1)

  # Tail-recursive range
  def range(from, to) do
    # Your implementation with accumulator
    do_range(from, to, [])
  end

  defp do_range(from, to, acc) when from > to, do: Enum.reverse(acc)

  defp do_range(from, to, acc) do
    do_range(from + 1, to, [from | acc])
  end

  # Positive tail recursion
  def positive(list) do
    do_positive(list, [])
  end

  defp do_positive([], acc), do: acc

  defp do_positive([head | tail], acc) when head > 0 do
    do_positive(tail, [head | acc])
  end

  defp do_positive([_head | tail], acc) do
    do_positive(tail, acc)
  end

end


IO.puts("TailRecursion.list_length([1, 2, 3, 4, 5, 6, 7, 0]):")
IO.puts(TailRecursion.list_length([1, 2, 3, 4, 5, 6, 7, 0]))

IO.inspect(TailRecursion.range(3, 7), label: "TailRecursion.range(3, 7)")
IO.inspect(TailRecursion.range(5, 3), label: "TailRecursion.range(5, 3)")  # Should return []

IO.inspect(TailRecursion.positive([-2, 3, -1, 5, 0, -4]), label: "TailRecursion.positive([-2, 3, -1, 5, 0, -4])")  # Should return [3, 5]

# Drill 7: Higher-Order Functions with Enum
Rule.number(7)

products = [
  %{name: "Laptop", price: 999, category: :electronics},
  %{name: "Mouse", price: 25, category: :electronics},
  %{name: "Desk", price: 299, category: :furniture},
  %{name: "Chair", price: 199, category: :furniture},
  %{name: "Monitor", price: 349, category: :electronics}
]

product_names = Enum.map(products, fn x -> x.name end) # OR
product_names = Enum.map(products, &(&1.name))
IO.inspect(product_names, label: "Product names")

under_500 = Enum.filter(products, fn x -> x.price < 500 end)
under_500 = Enum.filter(products, &(&1.price < 500))
IO.inspect(under_500, label: "Under 500")

total = Enum.reduce(products, 0, fn element, acc -> element.price + acc end)
total = Enum.reduce(products, 0, &(&1.price + &2))
IO.inspect(total, label: "Total")

max_price = Enum.max_by(products, fn x -> x.price end)
max_price = Enum.max_by(products, &(&1.price))
IO.inspect(max_price, label: "Most Expensive Product is")


group = Enum.group_by(products, fn x -> x.category end)
group = Enum.group_by(products, &(&1.category))
IO.inspect(group, label: "Groups")


# Drill 8: Comprehensions
Rule.number(8)
# 1. Generate a list of all coordinates in a 5x5 grid: `[{0,0}, {0,1}, ..., {4,4}]`
coordinates = for x <- 0..4, y <- 0..4, do: {x,y}
IO.inspect(coordinates, label: "Coordinates")

# 2. Generate a map where keys are numbers 1-10 and values are their squares
squares = for x <- 1..10, into: %{} do {x, x*x} end
IO.inspect(squares, label: "Squares")

# 3. From a list of strings, create a list of {string, length} tuples for strings longer than 3 characters
strings = ["hi", "hello", "ok", "world", "bye"]
longer_than_3_chars = for x <- strings, String.length(x) > 3, do: {x, String.length(x)}
IO.inspect(longer_than_3_chars, label: "Strings longer than 3 chars")

# 4. Create a multiplication table (1-12) as a formatted list of strings
multiplication_table = for x <- 1..12, y <- 1..12 do "#{x} x #{y} = #{x*y}" end
IO.inspect(multiplication_table, label: "Multiplicaton table")

# Drill 9: Streams vs. Enum
Rule.number(9)

defmodule StreamPractice do
  def infinite_naturals do
    # Generate infinite stream starting at 1
    Stream.iterate(1, &(&1 + 1))
  end

  def first_n_odds(n) do
    # Use infinite_naturals and take n odd numbers
    infinite_naturals()
    |> Stream.filter(&rem(&1, 2) == 1)
    |> Enum.take(n)
  end

  def error_lines!(file_path) do
    # Use File.stream! and Stream operations
    File.stream!(file_path)
    |> Stream.map(&String.downcase/1)
    |> Stream.filter( &String.contains?(&1, "error"))
    |> Stream.map(&String.trim/1)
    |> Enum.to_list()
  end
end

IO.inspect(StreamPractice.infinite_naturals(), label: "Infinite Naturals")

IO.inspect(StreamPractice.first_n_odds(200), label: "First n odd numbers")

IO.inspect(StreamPractice.error_lines!("/workspace/Solution/chapter_03/error_file.txt"), label: "Lines with error")
