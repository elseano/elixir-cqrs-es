defmodule Cqrses.Commands.PlaceOrder do
  defstruct id: nil, items: []
end

defmodule Cqrses.Commands.TabNotOpen do
  defexception message: "Tab is not open"
end
