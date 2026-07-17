defmodule Petri.RNGTest do
  use ExUnit.Case, async: true

  alias Petri.RNG

  describe "maybe_seed/1" do
    test "seeds when seed is a positive integer" do
      RNG.maybe_seed([seed: 42])
      # After seeding, :rand should be deterministic
      v1 = :rand.uniform(1000)
      RNG.maybe_seed([seed: 42])
      v2 = :rand.uniform(1000)
      assert v1 == v2
    end

    test "does nothing when seed is nil" do
      # Should not raise
      assert :ok = RNG.maybe_seed([seed: nil])
    end
  end
end
