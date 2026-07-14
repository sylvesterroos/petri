defprotocol Petri.Chromosome do
  @moduledoc "Protocol for chromosome representations. Implementations provide `length/1`, `genes/1`, and `valid?/1`."
  @doc "Returns the number of genes in the chromosome."
  def length(chromosome)

  @doc "Returns the chromosome's gene list."
  def genes(chromosome)

  @doc """
  Returns true if the chromosome satisfies its representation's invariants
  (e.g. a permutation has no duplicate genes).
  """
  def valid?(chromosome)
end
