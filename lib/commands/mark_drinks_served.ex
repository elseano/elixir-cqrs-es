defmodule Cqrses.Commands.MarkDrinksServed do
  defstruct id: nil, menu_numbers: []
end

defmodule Cqrses.Commands.DrinksNotOutstanding do
  defexception message: "Drinks not outstanding"
end
