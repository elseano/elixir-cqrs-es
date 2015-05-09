defmodule Cqrses.Aggregates.Tab do
  defstruct id: nil, table_number: nil, waiter: nil, open: false

  alias Cqrses.Aggregates.Tab

  alias Cqrses.Commands.OpenTab
  alias Cqrses.Commands.PlaceOrder

  alias Cqrses.Events.TabOpened
  alias Cqrses.Events.DrinksOrdered
  alias Cqrses.Events.FoodOrdered

  def apply(tab, %TabOpened{ id: id, table_number: table_number, waiter: waiter }) do
    %Tab{ tab | id: id, table_number: table_number, waiter: waiter, open: true }
  end

  def perform(tab, %OpenTab{ id: id, table_number: table_number, waiter: waiter }) do
    [
      %TabOpened{ id: id, table_number: table_number, waiter: waiter }
    ]
  end

  def perform(tab, %PlaceOrder{ id: id, items: items }) do
    if !tab.open, do: raise Cqrses.Commands.TabNotOpen

    order_drinks(id, items) ++ order_food(id, items)
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

defmodule Cqrses.Aggregates.TabTest do
  use ExUnit.Case

  alias Cqrses.Aggregates.Tab
  alias Cqrses.Commands.OpenTab
  alias Cqrses.Commands.PlaceOrder

  alias Cqrses.Events.TabOpened
  alias Cqrses.Events.DrinksOrdered
  alias Cqrses.Events.FoodOrdered

  alias Cqrses.OrderedItem

  test "can open a new tab" do
    id = UUID.uuid1()
    number = 42
    waiter = "Derek"

    command = %OpenTab{ id: id, table_number: number, waiter: waiter }

    assert Tab.perform(%Tab{}, command) == [%TabOpened{ id: id, table_number: number, waiter: waiter }]
  end

  test "can not order with unopened tab" do
    id = UUID.uuid1()
    command = %PlaceOrder{ id: id, items: [ %OrderedItem{} ] }

    assert_raise Cqrses.Commands.TabNotOpen, fn -> Tab.perform(%Tab{}, command) end
  end

  test "can place drinks order" do
    id = UUID.uuid1()
    number = 42
    waiter = "Derek"

    drink1 = %OrderedItem{ menu_number: 1, is_drink: true }
    drink2 = %OrderedItem{ menu_number: 2, is_drink: true }

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: number, waiter: waiter })

    command = %PlaceOrder{ id: id, items: [ drink1, drink2 ] }

    assert Tab.perform(tab, command) == [%DrinksOrdered{ id: id, items: [ drink1, drink2 ] }]
  end

  test "can place food order" do
    id = UUID.uuid1()
    number = 42
    waiter = "Derek"

    food1 = %OrderedItem{ menu_number: 1, is_drink: false }
    food2 = %OrderedItem{ menu_number: 2, is_drink: false }

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: number, waiter: waiter })

    command = %PlaceOrder{ id: id, items: [ food1, food2 ] }

    assert Tab.perform(tab, command) == [%FoodOrdered{ id: id, items: [ food1, food2 ] }]
  end

  test "can place food and drink order" do
    id = UUID.uuid1()
    number = 42
    waiter = "Derek"

    drink1 = %OrderedItem{ menu_number: 1, is_drink: true }
    drink2 = %OrderedItem{ menu_number: 2, is_drink: true }
    food1 = %OrderedItem{ menu_number: 1, is_drink: false }
    food2 = %OrderedItem{ menu_number: 2, is_drink: false }

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: number, waiter: waiter })

    command = %PlaceOrder{ id: id, items: [ drink1, drink2, food1, food2 ] }

    assert Tab.perform(tab, command) == [%DrinksOrdered{ id: id, items: [ drink1, drink2 ] }, %FoodOrdered{ id: id, items: [ food1, food2 ] }]
  end
end
