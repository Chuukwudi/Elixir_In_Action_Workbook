#!/usr/bin/env elixir

# Demo script for ContactManager system
# Run with: elixir demo.exs

# Compile all modules
Code.compile_file("contact_manager.ex")
Code.compile_file("formatter.ex")
Code.compile_file("query.ex")
Code.compile_file("examples.ex")

# Run the comprehensive demonstration
ContactManager.Examples.demo()
