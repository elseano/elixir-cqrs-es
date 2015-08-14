defmodule Cqrses.Aggregates.TabTest do
  use ExUnit.Case, async: true

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

  alias Cqrses.OrderedItem

  setup do
    { :ok, [
      waiter: "Derek",
      table: 42,
      drink1: %OrderedItem{ menu_number: 1, is_drink: true, price: 4 },
      drink2: %OrderedItem{ menu_number: 2, is_drink: true, price: 7 },
      food1: %OrderedItem{ menu_number: 10, is_drink: false, price: 14 },
      food2: %OrderedItem{ menu_number: 20, is_drink: false, price: 15 }
    ]}
  end

  test "can open a new tab", context do
    id = UUID.uuid1()

    command = %OpenTab{ id: id, table_number: context.table, waiter: context.waiter }

    assert Tab.perform(%Tab{}, command) == [%TabOpened{ id: id, table_number: context.table, waiter: context.waiter }]
  end

  test "can not order with unopened tab" do
    id = UUID.uuid1()
    command = %PlaceOrder{ id: id, items: [ %OrderedItem{} ] }

    assert_raise Cqrses.Commands.TabNotOpen, fn -> Tab.perform(%Tab{}, command) end
  end

  test "can place drinks order", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })

    command = %PlaceOrder{ id: id, items: [ context.drink1, context.drink2 ] }

    assert Tab.perform(tab, command) == [%DrinksOrdered{ id: id, items: [ context.drink1, context.drink2 ] }]
  end

  test "can place food order", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })

    command = %PlaceOrder{ id: id, items: [ context.food1, context.food2 ] }

    assert Tab.perform(tab, command) == [%FoodOrdered{ id: id, items: [ context.food1, context.food2 ] }]
  end

  test "can place food and drink order", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })

    command = %PlaceOrder{ id: id, items: [ context.drink1, context.drink2, context.food1, context.food2 ] }

    assert Tab.perform(tab, command) == [%DrinksOrdered{ id: id, items: [ context.drink1, context.drink2 ] }, %FoodOrdered{ id: id, items: [ context.food1, context.food2 ] }]
  end

  test "ordered drinks can be served", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })
    tab = Tab.apply(tab, %DrinksOrdered{ id: id, items: [ context.drink1, context.drink2 ] })

    command = %MarkDrinksServed{ id: id, menu_numbers: [context.drink1.menu_number, context.drink2.menu_number] }

    assert Tab.perform(tab, command) == [%DrinksServed{ id: id, menu_numbers: [context.drink1.menu_number, context.drink2.menu_number] }]
  end

  test "can not serve an unordered drink", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })
    tab = Tab.apply(tab, %DrinksOrdered{ id: id, items: [context.drink2] })

    command = %MarkDrinksServed{ id: id, menu_numbers: [context.drink1.menu_number] }

    assert_raise Cqrses.Commands.DrinksNotOutstanding, fn -> Tab.perform(tab, command) end
  end

  test "can not serve an ordered drink twice", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })
    tab = Tab.apply(tab, %DrinksOrdered{ id: id, items: [context.drink1] })
    tab = Tab.apply(tab, %DrinksServed{ id: id, menu_numbers: [context.drink1.menu_number] })

    command = %MarkDrinksServed{ id: id, menu_numbers: [context.drink1.menu_number] }

    assert_raise Cqrses.Commands.DrinksNotOutstanding, fn -> Tab.perform(tab, command) end
  end

  test "can close tab with tip", context do
    id = UUID.uuid1()

    tab = Tab.apply(%Tab{}, %TabOpened{ id: id, table_number: context.table, waiter: context.waiter })
    tab = Tab.apply(tab, %DrinksOrdered{ id: id, items: [context.drink1] })
    tab = Tab.apply(tab, %DrinksServed{ id: id, menu_numbers: [context.drink1.menu_number] })

    command = %CloseTab{ id: id, amount_paid: 20 }

    assert Tab.perform(tab, command) == []
  end

end
