defmodule Proj3Test do
  use ExUnit.Case
  doctest Proj3
  doctest Mainmodule

  test "greets the world" do
    assert Mainmodule.main(["20", "10"])=="kcdbhjwebc"

  end
end
