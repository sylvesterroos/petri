Mix.install([{:petri, path: "."}, :nx])

defmodule MLHyperparams do
  @moduledoc """
  Tunes learning rate, L2 regularization, and training epochs for a linear
  regression model using a real-coded GA.

  The dataset is synthetic: 10 features, target = 2x₁ + 3x₂ − 1.5x₃ + noise.
  Each fitness evaluation trains a model from scratch with the candidate
  hyperparameters and scores it on a held-out test set.

  Uses Nx for tensor operations.
  """

  alias Petri.Chromosome.Real

  @n_features 10
  @true_weights Nx.tensor([2.0, 3.0, -1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

  @n_train 100
  @n_test 40

  @doc """
  Runs the hyperparameter tuning GA and prints results.
  """
  def run do
    # Synthetic dataset: 10 features but only the first 3 carry signal.
    # The true relationship is y = 2x₁ + 3x₂ − 1.5x₃ + ε, where ε ~ N(0, 0.01).
    # ε is Gaussian noise (mean 0, std dev 0.1) that models measurement error and
    # unobserved factors. Without it the relationship would be deterministic and any
    # model could fit perfectly; the noise makes it realistic and tests whether the
    # GA can find hyperparameters that recover the signal through the scatter.
    # Features 4–10 are noise, but the GA doesn't know that. It has to learn
    # which hyperparameters let the model fit the signal and ignore the rest.
    key = Nx.Random.key(99)
    keys = Nx.Random.split(key, parts: 4)

    {train_x, _key} = Nx.Random.uniform(Nx.take(keys, 0), shape: {@n_train, @n_features})
    {test_x, _key} = Nx.Random.uniform(Nx.take(keys, 1), shape: {@n_test, @n_features})

    {noise_train, _key} = Nx.Random.normal(Nx.take(keys, 2), 0.0, 0.01, shape: {@n_train})
    {noise_test, _key} = Nx.Random.normal(Nx.take(keys, 3), 0.0, 0.01, shape: {@n_test})

    train_y = Nx.add(Nx.dot(train_x, @true_weights), noise_train)
    test_y = Nx.add(Nx.dot(test_x, @true_weights), noise_test)

    oracle_r2 = r2(test_y, Nx.dot(test_x, @true_weights))

    fitness = fn %Real{genes: [lr, lambda, epochs]} ->
      epochs_int = max(1, round(epochs))
      weights = train(train_x, train_y, lr, lambda, epochs_int)
      r2(test_y, Nx.dot(test_x, weights))
    end

    # BLX-α creates offspring in an interval extending beyond the parents
    # by a fraction α of their distance, which helps explore continuous
    # spaces without getting stuck. Gaussian mutation adds small
    # perturbations for local fine-tuning.
    result =
      Petri.run(fitness, %{
        encoding: :real,
        bounds: [
          {1.0e-4, 1.0e-1},
          {1.0e-6, 1.0e-1},
          {10.0, 200.0}
        ],
        population_size: 50,
        max_generations: 40,
        seed: 42,
        selection: :tournament,
        tournament_size: 3,
        elite_count: 3,
        crossover: :blx_alpha,
        blx_alpha_param: 0.5,
        mutation: :gaussian,
        gaussian_sigma: 0.15,
        mutation_rate: 0.3
      })

    {best_chromosome, best_fitness} = result.best
    [lr, lambda, epochs] = best_chromosome.genes

    # Retrain with the best hyperparams on all data to get final weights.
    all_x = Nx.concatenate([train_x, test_x])
    all_y = Nx.concatenate([train_y, test_y])
    final_weights = train(all_x, all_y, lr, lambda, round(epochs))

    IO.puts("""
    ML Hyperparameter Tuning — Linear Regression
    ============================================
    generations run: #{result.generations_run}
    evaluations:     #{result.evaluations}

    Best hyperparameters found:
      learning rate:       #{:erlang.float_to_binary(lr, decimals: 6)}
      L2 regularization:   #{:erlang.float_to_binary(lambda, decimals: 8)}
      training epochs:     #{round(epochs)}

    Test R² achieved:      #{:erlang.float_to_binary(best_fitness, decimals: 4)}
    Oracle R² (true wts):  #{:erlang.float_to_binary(oracle_r2, decimals: 4)}

    Learned weights vs true weights:
    #{weight_table(Nx.to_list(final_weights), Nx.to_list(@true_weights))}
    """)
  end

  # Vanilla gradient descent. The dataset is small enough to use the full
  # batch each step. L2 regularization (lambda) shrinks weights toward zero,
  # which helps when the model has more features than signal.
  defp train(x, y, lr, lambda, epochs) do
    n_features = Nx.axis_size(x, 1)
    n = Nx.axis_size(x, 0)
    w = Nx.broadcast(0.0, {n_features})

    Enum.reduce(1..epochs, w, fn _, w ->
      pred = Nx.dot(x, w)
      error = Nx.subtract(pred, y)
      grad = Nx.add(Nx.dot(Nx.transpose(x), error) |> Nx.divide(n), Nx.multiply(lambda, w))
      Nx.subtract(w, Nx.multiply(lr, grad))
    end)
  end

  # R² = 1 − (residual sum of squares / total sum of squares).
  # 1.0 means perfect prediction, 0.0 means the model is no better than
  # predicting the mean. Can go negative if the model is worse than that.
  defp r2(y_true, y_pred) do
    y_mean = Nx.mean(y_true)
    ss_res = Nx.sum(Nx.pow(Nx.subtract(y_true, y_pred), 2))
    ss_tot = Nx.sum(Nx.pow(Nx.subtract(y_true, y_mean), 2))
    if Nx.to_number(ss_tot) == 0.0, do: 1.0, else: 1.0 - Nx.to_number(Nx.divide(ss_res, ss_tot))
  end

  defp weight_table(learned, target) do
    header = "  feature | learned | true\n  --------|---------|------"

    rows =
      Enum.zip([learned, target])
      |> Enum.with_index(1)
      |> Enum.map(fn {{l, t}, i} ->
        sl = :erlang.float_to_binary(l, decimals: 4) |> String.pad_leading(7)
        st = :erlang.float_to_binary(t, decimals: 4) |> String.pad_leading(7)
        "  #{Integer.to_string(i) |> String.pad_leading(7)} | #{sl} | #{st}"
      end)
      |> Enum.join("\n")

    header <> "\n" <> rows
  end
end

MLHyperparams.run()
