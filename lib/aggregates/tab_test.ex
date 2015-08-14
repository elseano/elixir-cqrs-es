defmodule Cqrses.Aggregates.Tab do
  defstruct id: nil, table_number: nil, waiter: nil, open: false, outstanding_drinks: []

  alias Cqrses.Aggregates.Tab

  alias Cqrses.Commands.OpenTab
  alias Cqrses.Commands.PlaceOrder
  alias Cqrses.Commands.MarkDrinksServed
  alias Cqrses.Commands.CloseTab

  alias Cqrses.Events.TabOpened
  alias Cqrses.Events.DrinksOrdered
  alias Cqrses.Events.FoodOrdered
  alias Cqrses.Events.DrinksServed
  alias Cqrses.Events.TabClosed

  def drinks_outstanding?(tab, []) do
    true
  end

  def drinks_outstanding?(drinks_outstanding, [menu_number | other_numbers]) do
    if Enum.member?(drinks_outstanding, menu_number) do
      drinks_outstanding?(List.delete(drinks_outstanding, menu_number), other_numbers)
    else
      false
    end
  end

  def apply(tab, %TabOpened{ id: id, table_number: table_number, waiter: waiter }) do
    %Tab{ tab | id: id, table_number: table_number, waiter: waiter, open: true }
  end

  def apply(tab, %DrinksOrdered{ id: id, items: items }) do
    drinks = Enum.map items, fn (item) -> item.menu_number end

    %Tab{ tab | outstanding_drinks: tab.outstanding_drinks ++ drinks}
  end

  def apply(tab, %DrinksServed{ id: id, menu_numbers: menu_numbers }) do
    %Tab{ tab | outstanding_drinks: tab.outstanding_drinks -- menu_numbers}
  end

  def perform(tab, %OpenTab{ id: id, table_number: table_number, waiter: waiter }) do
    [
      %TabOpened{ id: id, table_number: table_number, waiter: waiter }
    ]
  end

  def perform(tab, %MarkDrinksServed{ id: id, menu_numbers: menu_numbers }) do
    unless drinks_outstanding?(tab.outstanding_drinks, menu_numbers) do
      raise Cqrses.Commands.DrinksNotOutstanding
    end

    [
      %DrinksServed{ id: id, menu_numbers: menu_numbers }
    ]
  end

  def perform(tab, %PlaceOrder{ id: id, items: items }) do
    if !tab.open, do: raise Cqrses.Commands.TabNotOpen

    order_drinks(id, items) ++ order_food(id, items)
  end

  def perform(tab, %CloseTab{ id: id, amount_paid: amount_paid}) do

    []
  end

  defp order_drinks(id, items) do
    items = Enum.filter(items, fn(x) -> x.is_drink end)

    if length(items) > 1 do
      [%DrinksOrdered{ id: id, items: items }]
    else
      []
    end
  end

  defp order_food(id, items) do
    items = Enum.filter(items, fn(x) -> !x.is_drink end)

    if length(items) > 1 do
      [%FoodOrdered{ id: id, items: items }]
    else
      []
    end
  end

end
