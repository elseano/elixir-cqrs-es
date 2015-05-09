defmodule Cqrses.Events.FoodOrdered do
  defstruct id: UUID.uuid1(), items: []
end
