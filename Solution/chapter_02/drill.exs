defmodule Drill do
  def number(n) do
    IO.puts("\n #{String.duplicate("-", 50)} Drill #{String.pad_leading("#{n}", 2, "0")} #{String.duplicate("-", 50)}\n")
  end
end

# Drill 1: Interactive Shell Basics
Drill.number(1)

IO.puts("(10 + 5) * 3 - 7 = #{(10 + 5) * 3 - 7}")

price = 99.99
IO.puts("Price for 3 items is £#{Float.ceil(price * 3, 2)}")

price = 89.99
IO.puts("Price for 3 items is £#{price * 3 |> Float.ceil(2)}")

# Drill 2: Module and Function Creation
Drill.number(2)

defmodule Temperature do

  def f_to_c(fahrenheit) do
    (fahrenheit - 32) * 5 / 9
  end

  def c_to_f(celsius) do
    (celsius * 9 / 5) + 32
  end

  def c_to_k(celsius) do
    celsius + 273.15
  end

end

IO.puts("Temperature.f_to_c(32) = #{Temperature.f_to_c(32)}")    # => 0.0
IO.puts("Temperature.c_to_f(0)  = #{Temperature.c_to_f(0)}")     # => 32.0
IO.puts("Temperature.c_to_k(0)  = #{Temperature.c_to_k(0)}")     # => 273.15

# Drill 3: Understanding Arity
Drill.number(3)

defmodule Greeter do
  def hello(name \\ "World") do
    "Hello, #{name}!"
  end

  def hello(greeting, name) do
    "#{greeting}, #{name}!"
  end

end

IO.puts("Greeter.hello()            = #{Greeter.hello()}")                # => "Hello, World!"
IO.puts("Greeter.hello(\"Alice\")     = #{Greeter.hello("Alice")}")       # => "Hello, Alice!"
IO.puts("Greeter.hello(\"Bob\", \"Hi\") = #{Greeter.hello("Hi", "Bob")}") # => "Hi, Bob!"

# Drill 4: Atoms and Pattern Matching
Drill.number(4)

defmodule AnAtom do
  def status_message(:ok), do: "Success!"
  def status_message(:error), do: "Something went wrong"
  def status_message(:pending), do: "Processing..."
  def status_message(_), do: "Unknown status"
end

ok = :ok
error = :error
pending = :pending
contains_spaces = :"contains spaces"

IO.puts("AnAtom == :\"Elixir.AnAtom\" is #{AnAtom == :"Elixir.AnAtom"}") # Should print true
IO.puts("Status :ok      = #{AnAtom.status_message(ok)}")
IO.puts("Status :error   = #{AnAtom.status_message(error)}")
IO.puts("Status :pending = #{AnAtom.status_message(pending)}")
IO.puts("Status :other   = #{AnAtom.status_message(:other)}")

# Drill 5: Tuples vs Lists
Drill.number(5)

person = {"Alice", 30, "Engineer"}
IO.inspect(person, label: "Person Tuple is")
IO.puts("Age is #{elem(person, 1)}")
updated_person = put_elem(person, 1, 31)
IO.inspect(updated_person, label: "Updated Person Tuple is")

prime_numbers = [2, 3, 5, 7, 11, "djddd"]
IO.inspect(prime_numbers, label: "Prime Numbers List is")
IO.puts("The length of prime_numbers list is #{length(prime_numbers)}")
add_to_begginning = [13 | prime_numbers]
IO.inspect(add_to_begginning, label: "List after adding to beginning is")
add_to_end = prime_numbers ++ [17]
IO.inspect(add_to_end, label: "List after adding to end is")

when_to_use_tuple = "Use a Tuple when you have a fixed number of elements."
when_to_use_list = "Use a List when you have a variable number of elements."
IO.puts(when_to_use_tuple)
IO.puts(when_to_use_list)

# Drill 6: Map Manipulation
Drill.number(6)
IO.puts("Part A - Dynamic Map:")
map = %{}
IO.inspect(map, label: "Empty Map is")
map = Map.put(map, :monday, 100)
map = Map.put(map, :tuesday, 150)

# The above can be achieved more beautifully using:
# map = Map.merge(map, %{monday: 100, tuesday: 150})
# or by chaining Map.put/3 calls:
# map = map |> Map.put(:monday, 100) |> Map.put(:tuesday, 150)
# Assuming the keys already exist, map can be updated like this:
# map = %{map | monday: 100, tuesday: 150}

IO.inspect(map, label: "Map after adding :monday and :tuesday keys is")

IO.puts("Value for :tuesday is #{Map.get(map, :tuesday)}")
map = %{map | monday: 120}
IO.inspect(map, label: "Map after updating :monday")

IO.puts("Part B - Structured Data:")
book = %{title: "Elixir in Action", author: "Saša Jurić", pages: 400}
IO.inspect(book, label: "Book Map is")
IO.puts("The author of the book is #{book.author}")
book = %{book | pages: 450}
IO.inspect(book, label: "Book Map after updating pages")

# Drill 7: Immutability Demonstration
Drill.number(7)

original = [1, 2, 3]
modified = original ++ [4]

IO.inspect(original, label: "Original List is")
IO.inspect(modified, label: "Modified List is")

# Explain what happened in memory (draw and describe):
IO.puts("""
The original list remains unchanged because Elixir data structures are immutable.
When we create the modified list by appending 4, a new list is created in memory,
leaving the original list intact.
""")

original_tuple = {1, 2, 3}
modified_tuple = put_elem(original_tuple, 1, 20)

IO.inspect(original_tuple, label: "Original Tuple is")
IO.inspect(modified_tuple, label: "Modified Tuple is")
IO.puts("""
Similar to lists, tuples in Elixir are also immutable.
When we modify a tuple, a new tuple is created in memory,
and the original tuple remains unchanged.
"""
)

# Drill 8: String Operations
Drill.number(8)

# Task:

# Create a string with interpolation: "Result: #{10 + 5}"
# Create a multi-line string using """
# Concatenate two strings using <>
# Use a sigil: ~s(String with "quotes")
# Convert between binary string and character list

interpolated_string = "Result: #{10 + 5}"
IO.puts("Interpolated string is: #{interpolated_string}")
multi_line_string = """
This is a
multi-line
string.
"""

IO.puts("Multi-line string is:\n#{multi_line_string}")
concatenated_string = "Hello, " <> "World!"
IO.puts("Concatenated string is: #{concatenated_string}")
sigil_string = ~s(String with "quotes")
IO.puts("Sigil string is: #{sigil_string}")

char_list = ~c"Hello"
IO.inspect(char_list, label: "Character List is")
binary_string = to_string(char_list)
IO.puts("Converted Binary String is: #{binary_string}")
