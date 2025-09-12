defmodule DrawingTest do
  use ExUnit.Case
  doctest Drawing

  test "greets the world" do
    assert Drawing.hello() == :world
  end
end
