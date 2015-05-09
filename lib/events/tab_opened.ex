defmodule Cqrses.Events.TabOpened do
  defstruct id: UUID.uuid1(), table_number: nil, waiter: nil
end
