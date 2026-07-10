defmodule Petri.Crossover.Permutation do
  alias Petri.Chromosome.Permutation

  def ox(%Permutation{genes: p0}, %Permutation{genes: p1}, config)
      when is_list(p0) and is_list(p1) do
    {c0_genes, c1_genes} = ox_genes(p0, p1, config)
    {%Permutation{genes: c0_genes}, %Permutation{genes: c1_genes}}
  end

  def pmx(%Permutation{genes: p0}, %Permutation{genes: p1}, config)
      when is_list(p0) and is_list(p1) do
    {c0_genes, c1_genes} = pmx_genes(p0, p1, config)
    {%Permutation{genes: c0_genes}, %Permutation{genes: c1_genes}}
  end

  def cx(%Permutation{genes: p0}, %Permutation{genes: p1}, _config)
      when is_list(p0) and is_list(p1) do
    {c0_genes, c1_genes} = cx_genes(p0, p1)
    {%Permutation{genes: c0_genes}, %Permutation{genes: c1_genes}}
  end

  ## Order Crossover (OX)

  defp ox_genes(p0, p1, _config) do
    len0 = length(p0)
    len1 = length(p1)

    if len0 != len1 do
      raise ArgumentError, "parent lengths differ (#{len0} vs #{len1})"
    end

    if len0 < 2 do
      {p0, p1}
    else
      [a, b] = Enum.sort(Enum.take_random(0..(len0 - 1), 2))
      {ox_child(p0, p1, a, b), ox_child(p1, p0, a, b)}
    end
  end

  defp ox_child(donor, filler, cp1, cp2) do
    n = length(donor)
    segment_set = MapSet.new(Enum.slice(donor, cp1..cp2))

    filler_cycle =
      (Enum.drop(filler, cp2 + 1) ++ Enum.take(filler, cp2 + 1))
      |> Enum.reject(&MapSet.member?(segment_set, &1))

    child =
      0..(n - 1)
      |> Enum.map(fn
        i when i >= cp1 and i <= cp2 -> Enum.at(donor, i)
        _ -> hd(filler_cycle)
      end)
      |> fill_ox_tail(filler_cycle, cp1, cp2)

    child
  end

  defp fill_ox_tail(child, filler_cycle, cp1, cp2) do
    {filled, _} =
      Enum.reduce(0..(length(child) - 1), {[], filler_cycle}, fn
        i, {acc, queue} when i >= cp1 and i <= cp2 ->
          {[Enum.at(child, i) | acc], queue}

        _i, {acc, [g | rest]} ->
          {[g | acc], rest}
      end)

    Enum.reverse(filled)
  end

  ## Partially Mapped Crossover (PMX)

  defp pmx_genes(p0, p1, _config) do
    len0 = length(p0)
    len1 = length(p1)

    if len0 != len1 do
      raise ArgumentError, "parent lengths differ (#{len0} vs #{len1})"
    end

    if len0 < 2 do
      {p0, p1}
    else
      [a, b] = Enum.sort(Enum.take_random(0..(len0 - 1), 2))
      {pmx_child(p0, p1, a, b), pmx_child(p1, p0, a, b)}
    end
  end

  defp pmx_child(src, fill, cp1, cp2) do
    n = length(src)
    src_arr = :array.from_list(src) |> :array.fix()
    fill_arr = :array.from_list(fill) |> :array.fix()
    pos_fill = Map.new(Enum.with_index(fill), fn {v, i} -> {v, i} end)

    segment = for i <- cp1..cp2, do: :array.get(i, src_arr)
    segment_set = MapSet.new(segment)

    child = :array.new([{:size, n}, :fixed, {:default, :undefined}])

    child
    |> place_segment(src_arr, cp1, cp2)
    |> relocate_from_fill(src_arr, fill_arr, cp1, cp2, segment_set, pos_fill)
    |> fill_remaining(fill_arr)
  end

  defp place_segment(child, src_arr, cp1, cp2) do
    Enum.reduce(cp1..cp2, child, fn i, acc ->
      :array.set(i, :array.get(i, src_arr), acc)
    end)
  end

  defp relocate_from_fill(child, src_arr, fill_arr, cp1, cp2, segment_set, pos_fill) do
    Enum.reduce(cp1..cp2, child, fn i, acc ->
      m = :array.get(i, fill_arr)

      if MapSet.member?(segment_set, m) do
        acc
      else
        n_gene = :array.get(i, src_arr)
        j = empty_slot(acc, Map.fetch!(pos_fill, n_gene), pos_fill)
        :array.set(j, m, acc)
      end
    end)
  end

  defp empty_slot(child, j, pos_fill) do
    case :array.get(j, child) do
      :undefined -> j
      k -> empty_slot(child, Map.fetch!(pos_fill, k), pos_fill)
    end
  end

  defp fill_remaining(child, fill_arr) do
    placed =
      :array.to_list(child)
      |> Enum.reject(&(&1 == :undefined))
      |> MapSet.new()

    size = :array.size(child)
    remaining = Enum.reject(:array.to_list(fill_arr), fn g -> MapSet.member?(placed, g) end)

    {child, _} =
      Enum.reduce(0..(size - 1), {child, remaining}, fn i, {acc, queue} ->
        case :array.get(i, acc) do
          :undefined ->
            [g | rest] = queue
            {:array.set(i, g, acc), rest}

          _ ->
            {acc, queue}
        end
      end)

    :array.to_list(child)
  end

  ## Cycle Crossover (CX)

  defp cx_genes(p0, p1) do
    n = length(p0)
    pos_in_p1 = Map.new(Enum.with_index(p1), fn {v, i} -> {v, i} end)

    cycle =
      Stream.iterate(0, fn i -> Map.fetch!(pos_in_p1, Enum.at(p0, i)) end)
      |> Enum.reduce_while(MapSet.new(), fn i, acc ->
        if MapSet.member?(acc, i) do
          {:halt, acc}
        else
          {:cont, MapSet.put(acc, i)}
        end
      end)

    c0 =
      for i <- 0..(n - 1) do
        if MapSet.member?(cycle, i), do: Enum.at(p0, i), else: Enum.at(p1, i)
      end

    c1 =
      for i <- 0..(n - 1) do
        if MapSet.member?(cycle, i), do: Enum.at(p1, i), else: Enum.at(p0, i)
      end

    {c0, c1}
  end
end
