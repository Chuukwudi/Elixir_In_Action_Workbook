
defmodule Geometry do
  defmodule Shapes do
    @moduledoc """
    A module for calculating areas and perimeters of basic geometric shapes.
    """
    defmodule Circle do

      def area(radius) do
          :math.pi() * radius * radius
        end

      def circumference(radius) do
          2 * :math.pi() * radius
        end

    end

    defmodule Rectangle do

      def area(length, width) do
          length * width
        end

      def perimeter(length, width) do
          2 * (length + width)
        end

    end

    defmodule Triangle do
      def area(base, height) do
          0.5 * base * height
        end

      def perimeter(side1, side2, side3) do
          side1 + side2 + side3
        end
    end
  end
end


# alias Geometry.Shapes.Circle
# Circle == :"Elixir.Geometry.Shapes.Circle"
# IO.puts("Circle module exists: #{Circle == :"Elixir.Geometry.Shapes.Circle"}")
# IO.puts("Circle area with radius 5: #{Circle.area(5)}")
# IO.puts("Circle circumference with radius 5: #{Circle.circumference(5)}")


# # Clean up first
# rm *.beam

# # Compile
# elixirc geometry.ex

# # List .beam files created
# ls -la *.beam

# # Start iex in this directory
# iex

# # Part A: Use the modules
# Geometry.Shapes.Circle.area(5)
# Geometry.Shapes.Rectangle.area(4, 6)
# Geometry.Shapes.Triangle.area(10, 5)

# # Part B: Module names are atoms
# alias Geometry.Shapes.Circle
# Circle == :"Elixir.Geometry.Shapes.Circle"  # => true

# # Prove hierarchical naming is just convention
# Geometry.Shapes.Circle == :"Elixir.Geometry.Shapes.Circle"  # => true

# # The parent modules don't "contain" child modules
# Geometry.Shapes.Circle  # Works
# Geometry                # This module exists but has no functions
