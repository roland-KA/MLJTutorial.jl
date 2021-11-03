### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 24abafc3-0e26-4cd2-9bca-7c69b794f8ce
md"# Machine Learning in Julia"

# ╔═╡ b67c62c2-15ab-4328-b795-033f6f2a0674
md"""
An introduction to the
[MLJ](https://alan-turing-institute.github.io/MLJ.jl/stable/)
toolbox.
"""

# ╔═╡ bc689638-fd19-4c9f-935f-ddf6a6bfbbdd
md"### Set-up"

# ╔═╡ 197fd00e-9068-46ea-af2a-25235e544a31
md"Inspect Julia version:"

# ╔═╡ f6d4f8c4-e441-45c4-8af5-148d95ea2900
VERSION

# ╔═╡ 45740c4d-b789-45dc-a6bf-47194d7e8e12
md"The following instantiates a package environment."

# ╔═╡ 42b0f1e1-16c9-4238-828a-4cc485149963
md"""
The package environment has been created using **Julia 1.6** and may not
instantiate properly for other Julia versions.
"""

# ╔═╡ d09256dd-6c0d-4e28-9e54-3f7b3ca87ecb
begin
  using Pkg
  Pkg.activate("env")
  Pkg.instantiate()
end

# ╔═╡ 499cbc31-83ba-4583-ba1f-6363f43ec697
md"## General resources"

# ╔═╡ db5821e8-956a-4a46-95ea-2955abd45275
md"""
- [MLJ Cheatsheet](https://alan-turing-institute.github.io/MLJ.jl/dev/mlj_cheatsheet/)
- [Common MLJ Workflows](https://alan-turing-institute.github.io/MLJ.jl/dev/common_mlj_workflows/)
- [MLJ manual](https://alan-turing-institute.github.io/MLJ.jl/dev/)
- [Data Science Tutorials in Julia](https://juliaai.github.io/DataScienceTutorials.jl/)
"""

# ╔═╡ 38fdb776-44b5-4df5-b1b3-dd47e367ba54
md"## Part 5 - Advanced Model Composition"

# ╔═╡ 23408dac-0ade-41f4-8d7e-8e449afd1c48
md"""
> **Goals:**
> 1. Learn how to build a prototypes of a composite model, called a *learning network*
> 2. Learn how to use the `@from_network` macro to export a learning network as a new stand-alone model type
"""

# ╔═╡ a6faf8b4-f0a5-4b16-a949-7f3bd292fe31
md"""
`@pipeline` is great for composing models in an unbranching
sequence. Another built-in type of model composition is a model
*stack*; see
[here](https://alan-turing-institute.github.io/MLJ.jl/dev/model_stacking/#Model-Stacking)
for details. For other complicated model compositions you'll want to
use MLJ's generic model composition syntax. There are two main
steps:
"""

# ╔═╡ ba20e440-5e12-431f-8514-99938a2932db
md"""
- **Prototype** the composite model by building a *learning
  network*, which can be tested on some (dummy) data as you build
  it.
"""

# ╔═╡ 5d9ff11f-89b2-4a7a-a0de-1721c1bc2df2
md"- **Export** the learning network as a new stand-alone model type."

# ╔═╡ 2da27496-95d4-43f3-bca8-7eec7950fd82
md"""
Like pipeline models, instances of the exported model type behave
like any other model (and are not bound to any data, until you wrap
them in a machine).
"""

# ╔═╡ bf69ff35-6d45-418e-9873-1b1430e635cc
md"### Building a pipeline using the generic composition syntax"

# ╔═╡ 3d480ea1-bba7-49de-b43e-d0ebe87da176
md"To warm up, we'll do the equivalent of"

# ╔═╡ ca5268eb-8d4b-4228-9009-4cfb2012998f
begin
  using MLJ
  LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
  pipe = @pipeline Standardizer LogisticClassifier;
end

# ╔═╡ 9e3a5fcf-8959-440c-abd3-cb77d7a79683
md"using the generic syntax."

# ╔═╡ 88ca15eb-49f8-4525-879e-dc128f3db7b3
md"Here's some dummy data we'll be using to test our learning network:"

# ╔═╡ 3e50886f-de5b-4941-a367-9aa3c6cf34d0
begin
  X, y = make_blobs(5, 3)
  pretty(X)
end

# ╔═╡ c720911a-478b-4aa0-bf32-94657e65284e
md"""
**Step 0** - Proceed as if you were combining the models "by hand",
using all the data available for training, transforming and
prediction:
"""

# ╔═╡ 48692370-0c4b-4080-9afd-65a5b5facac9
begin
  stand = Standardizer();
  linear = LogisticClassifier();
  
  mach1 = machine(stand, X);
  fit!(mach1);
  Xstand = transform(mach1, X);
  
  mach2 = machine(linear, Xstand, y);
  fit!(mach2);
  yhat = predict(mach2, Xstand)
end

# ╔═╡ b398bc7f-bf22-4bb5-b6c8-54f5ed90a964
md"**Step 1** - Edit your code as follows:"

# ╔═╡ a45aac02-b5d3-4dc2-9292-fe822525fc77
md"- pre-wrap the data in `Source` nodes"

# ╔═╡ 86e442b4-252f-439d-ae5e-4b83dcbc9675
md"- delete the `fit!` calls"

# ╔═╡ e193a088-1262-4b0f-8a29-32f11452654a
begin
  X = source(X)  # or X = source() if not testing
  y = source(y)  # or y = source()
  
  stand = Standardizer();
  linear = LogisticClassifier();
  
  mach1 = machine(stand, X);
  Xstand = transform(mach1, X);
  
  mach2 = machine(linear, Xstand, y);
  yhat = predict(mach2, Xstand)
end

# ╔═╡ 2f187af9-21d8-4c18-a5f1-151fcbe229a2
md"""
Now `X`, `y`, `Xstand` and `yhat` are *nodes* ("variables" or
"dynammic data") instead of data. All training, predicting and
transforming is now executed lazily, whenever we `fit!` one of these
nodes. We *call* a node to retrieve the data it represents in the
original manual workflow.
"""

# ╔═╡ 10b09adf-df0e-46c1-81bc-2d5603785a09
begin
  fit!(Xstand)
  Xstand() |> pretty
end

# ╔═╡ 50265a35-512f-4a2f-9d87-1d1fbb0e3997
begin
  fit!(yhat);
  yhat()
end

# ╔═╡ b53fc776-08cc-4b9d-b950-fddef2a1fb10
md"""
The node `yhat` is the "descendant" (in an associated DAG we have
defined) of a unique source node:
"""

# ╔═╡ ac92e1ee-e50c-4408-951b-64cb2a36c8e3
sources(yhat)

# ╔═╡ 4b9f5009-0e61-4ef7-b0e6-441461cc8770
md"""
The data at the source node is replaced by `Xnew` to obtain a
new prediction when we call `yhat` like this:
"""

# ╔═╡ 84d84a02-ae06-4f28-8cb0-de601961bc02
begin
  Xnew, _ = make_blobs(2, 3);
  yhat(Xnew)
end

# ╔═╡ c6d367a8-e734-4c1b-a87d-950c50fb2955
md"**Step 2** - Export the learning network as a new stand-alone model type"

# ╔═╡ 58693f6e-4e92-43f2-8448-4bcb089096cd
md"""
Now, somewhat paradoxically, we can wrap the whole network in a
special machine - called a *learning network machine* - before have
defined the new model type. Indeed doing so is a necessary step in
the export process, for this machine will tell the export macro:
"""

# ╔═╡ ffdeb6c4-ecd8-439d-a012-a84240254fb6
md"""
- what kind of model the composite will be (`Deterministic`,
  `Probabilistic` or `Unsupervised`)a
"""

# ╔═╡ 87752d2d-5a4c-460f-bbdd-9799f7bb2e60
md"- which source nodes are input nodes and which are for the target"

# ╔═╡ dddb76e8-6d64-4f19-97a7-88e3af4f10ee
md"""
- which nodes correspond to each operation (`predict`, `transform`,
  etc) that we might want to define
"""

# ╔═╡ 7ca171cd-cda4-4160-b372-8c9866e51852
begin
  surrogate = Probabilistic()     # a model with no fields!
  mach = machine(surrogate, X, y; predict=yhat)
end

# ╔═╡ 2d279802-6d07-4ec1-8f3d-b82f1e7b6f7a
md"""
Although we have no real need to use it, this machine behaves like
you'd expect it to:
"""

# ╔═╡ fd5d3c80-e1d3-49d4-ab04-579e5608ae53
begin
  Xnew, _ = make_blobs(2, 3)
  fit!(mach)
  predict(mach, Xnew)
end

# ╔═╡ 79f7e1b3-5648-430d-86cf-35420d9e6995
md"""
Now we create a new model type using a Julia `struct` definition
appropriately decorated:
"""

# ╔═╡ fd95ece8-48d5-4bb8-a29a-8d0445351914
@from_network mach begin
    mutable struct YourPipe
        standardizer = stand
        classifier = linear::Probabilistic
    end
end

# ╔═╡ 92c5cc35-1dde-4457-be65-28d0fcca50a8
md"Instantiating and evaluating on some new data:"

# ╔═╡ ee4593ba-0d78-487f-9a2e-c468345d87d1
begin
  pipe = YourPipe()
  X, y = @load_iris;   # built-in data set
  mach = machine(pipe, X, y)
  evaluate!(mach, measure=misclassification_rate, operation=predict_mode)
end

# ╔═╡ c52c087e-1ac1-4de2-b5fa-cb79ebf595ef
md"### A composite model to average two regressor predictors"

# ╔═╡ 76116413-6bef-4727-91c5-524da38aa391
md"""
The following is condensed version of
[this](https://github.com/alan-turing-institute/MLJ.jl/blob/master/binder/MLJ_demo.ipynb)
tutorial. We will define a composite model that:
"""

# ╔═╡ 2e3be684-3722-4ec3-ad90-b4405b216771
md"- standardizes the input data"

# ╔═╡ 702964b6-8a60-450e-895b-997a92b731e0
md"- learns and applies a Box-Cox transformation to the target variable"

# ╔═╡ 543aeb1a-53c0-4d91-a525-e9b04a4bd246
md"""
- blends the predictions of two supervised learning models - a ridge
 regressor and a random forest regressor; we'll blend using a simple
 average (for a more sophisticated stacking example, see
 [here](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/stacking/))
"""

# ╔═╡ ab16b5f0-7858-46df-80f0-ba7781e173cf
md"- applies the *inverse* Box-Cox transformation to this blended prediction"

# ╔═╡ 74b64063-8584-418b-9cbc-9a2c39793333
begin
  RandomForestRegressor = @load RandomForestRegressor pkg=DecisionTree
  RidgeRegressor = @load RidgeRegressor pkg=MLJLinearModels
end

# ╔═╡ c53ca29b-c401-458b-b887-2b16710e5502
md"**Input layer**"

# ╔═╡ 7cd952ac-837b-4cec-9452-5298a8a4a401
begin
  X = source()
  y = source()
end

# ╔═╡ fd9799d5-26f0-43d1-b017-96f1602f2cad
md"**First layer and target transformation**"

# ╔═╡ 8e62d2f3-5dbb-4e3a-8be2-2a4017c45345
begin
  std_model = Standardizer()
  stand = machine(std_model, X)
  W = MLJ.transform(stand, X)
  
  box_model = UnivariateBoxCoxTransformer()
  box = machine(box_model, y)
  z = MLJ.transform(box, y)
end

# ╔═╡ 04cacf81-e396-463e-a7ad-80d84f5b0070
md"**Second layer**"

# ╔═╡ 297612c4-9944-4dc5-8378-5aa686f0b407
begin
  ridge_model = RidgeRegressor(lambda=0.1)
  ridge = machine(ridge_model, W, z)
  
  forest_model = RandomForestRegressor(n_trees=50)
  forest = machine(forest_model, W, z)
  
  ẑ = 0.5*predict(ridge, W) + 0.5*predict(forest, W)
end

# ╔═╡ 863e750e-26b8-46e0-9f43-49763e8691a1
md"**Output**"

# ╔═╡ 39001eed-a445-4f44-bb0e-3a45761c733a
ŷ = inverse_transform(box, ẑ)

# ╔═╡ d8708b97-67f9-4143-9979-7044b2f2df33
md"With the learning network defined, we're ready to export:"

# ╔═╡ edd7008f-25a8-4613-b2a1-fbbde543f620
@from_network machine(Deterministic(), X, y, predict=ŷ) begin
    mutable struct CompositeModel
        rgs1 = ridge_model
        rgs2 = forest_model
    end
end

# ╔═╡ 16574eae-a0b7-4391-910b-f8a9a217eff2
md"Let's instantiate the new model type and try it out on some data:"

# ╔═╡ e4a3d173-fd0a-4529-aa36-d2e8546da46a
composite = CompositeModel()

# ╔═╡ c3896689-5775-4cd8-88a1-a2bf91434413
begin
  X, y = @load_boston;
  mach = machine(composite, X, y);
  evaluate!(mach,
            resampling=CV(nfolds=6, shuffle=true),
            measures=[rms, mae])
end

# ╔═╡ 3524e197-2629-4ee7-a1cb-54e34396a855
md"""
### Resources for Part 5

- From the MLJ manual:
   - [Learning Networks](https://alan-turing-institute.github.io/MLJ.jl/stable/composing_models/#Learning-Networks-1)
- From Data Science Tutorials:
    - [Learning Networks](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/learning-networks/)
    - [Learning Networks 2](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/learning-networks-2/)
"""

# ╔═╡ 1f6669aa-021b-4ae5-8037-0de5806e1a54
md"    - [Stacking](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/stacking/): an advanced example of model composition"

# ╔═╡ 0626a990-e862-4c92-9961-a09632c33fb0
md"""
    - [Finer Control](https://alan-turing-institute.github.io/MLJ.jl/dev/composing_models/#Method-II:-Finer-control-(advanced)-1):
      exporting learning networks without a macro for finer control
"""

# ╔═╡ ac4a8d2e-411c-43d5-b7cc-46f4ef988c68
md"<a id='solutions-to-exercises'></a>"

# ╔═╡ 135dac9b-0bd9-4e1d-90fb-7f2721f6fcc7
md"""
---

*This notebook was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
"""

# ╔═╡ Cell order:
# ╟─24abafc3-0e26-4cd2-9bca-7c69b794f8ce
# ╟─b67c62c2-15ab-4328-b795-033f6f2a0674
# ╟─bc689638-fd19-4c9f-935f-ddf6a6bfbbdd
# ╟─197fd00e-9068-46ea-af2a-25235e544a31
# ╠═f6d4f8c4-e441-45c4-8af5-148d95ea2900
# ╟─45740c4d-b789-45dc-a6bf-47194d7e8e12
# ╟─42b0f1e1-16c9-4238-828a-4cc485149963
# ╠═d09256dd-6c0d-4e28-9e54-3f7b3ca87ecb
# ╟─499cbc31-83ba-4583-ba1f-6363f43ec697
# ╟─db5821e8-956a-4a46-95ea-2955abd45275
# ╟─38fdb776-44b5-4df5-b1b3-dd47e367ba54
# ╟─23408dac-0ade-41f4-8d7e-8e449afd1c48
# ╟─a6faf8b4-f0a5-4b16-a949-7f3bd292fe31
# ╟─ba20e440-5e12-431f-8514-99938a2932db
# ╟─5d9ff11f-89b2-4a7a-a0de-1721c1bc2df2
# ╟─2da27496-95d4-43f3-bca8-7eec7950fd82
# ╟─bf69ff35-6d45-418e-9873-1b1430e635cc
# ╟─3d480ea1-bba7-49de-b43e-d0ebe87da176
# ╠═ca5268eb-8d4b-4228-9009-4cfb2012998f
# ╟─9e3a5fcf-8959-440c-abd3-cb77d7a79683
# ╟─88ca15eb-49f8-4525-879e-dc128f3db7b3
# ╠═3e50886f-de5b-4941-a367-9aa3c6cf34d0
# ╟─c720911a-478b-4aa0-bf32-94657e65284e
# ╠═48692370-0c4b-4080-9afd-65a5b5facac9
# ╟─b398bc7f-bf22-4bb5-b6c8-54f5ed90a964
# ╟─a45aac02-b5d3-4dc2-9292-fe822525fc77
# ╟─86e442b4-252f-439d-ae5e-4b83dcbc9675
# ╠═e193a088-1262-4b0f-8a29-32f11452654a
# ╟─2f187af9-21d8-4c18-a5f1-151fcbe229a2
# ╠═10b09adf-df0e-46c1-81bc-2d5603785a09
# ╠═50265a35-512f-4a2f-9d87-1d1fbb0e3997
# ╟─b53fc776-08cc-4b9d-b950-fddef2a1fb10
# ╠═ac92e1ee-e50c-4408-951b-64cb2a36c8e3
# ╟─4b9f5009-0e61-4ef7-b0e6-441461cc8770
# ╠═84d84a02-ae06-4f28-8cb0-de601961bc02
# ╟─c6d367a8-e734-4c1b-a87d-950c50fb2955
# ╟─58693f6e-4e92-43f2-8448-4bcb089096cd
# ╟─ffdeb6c4-ecd8-439d-a012-a84240254fb6
# ╟─87752d2d-5a4c-460f-bbdd-9799f7bb2e60
# ╟─dddb76e8-6d64-4f19-97a7-88e3af4f10ee
# ╠═7ca171cd-cda4-4160-b372-8c9866e51852
# ╟─2d279802-6d07-4ec1-8f3d-b82f1e7b6f7a
# ╠═fd5d3c80-e1d3-49d4-ab04-579e5608ae53
# ╟─79f7e1b3-5648-430d-86cf-35420d9e6995
# ╠═fd95ece8-48d5-4bb8-a29a-8d0445351914
# ╟─92c5cc35-1dde-4457-be65-28d0fcca50a8
# ╠═ee4593ba-0d78-487f-9a2e-c468345d87d1
# ╟─c52c087e-1ac1-4de2-b5fa-cb79ebf595ef
# ╟─76116413-6bef-4727-91c5-524da38aa391
# ╟─2e3be684-3722-4ec3-ad90-b4405b216771
# ╟─702964b6-8a60-450e-895b-997a92b731e0
# ╟─543aeb1a-53c0-4d91-a525-e9b04a4bd246
# ╟─ab16b5f0-7858-46df-80f0-ba7781e173cf
# ╠═74b64063-8584-418b-9cbc-9a2c39793333
# ╟─c53ca29b-c401-458b-b887-2b16710e5502
# ╠═7cd952ac-837b-4cec-9452-5298a8a4a401
# ╟─fd9799d5-26f0-43d1-b017-96f1602f2cad
# ╠═8e62d2f3-5dbb-4e3a-8be2-2a4017c45345
# ╟─04cacf81-e396-463e-a7ad-80d84f5b0070
# ╠═297612c4-9944-4dc5-8378-5aa686f0b407
# ╟─863e750e-26b8-46e0-9f43-49763e8691a1
# ╠═39001eed-a445-4f44-bb0e-3a45761c733a
# ╟─d8708b97-67f9-4143-9979-7044b2f2df33
# ╠═edd7008f-25a8-4613-b2a1-fbbde543f620
# ╟─16574eae-a0b7-4391-910b-f8a9a217eff2
# ╠═e4a3d173-fd0a-4529-aa36-d2e8546da46a
# ╠═c3896689-5775-4cd8-88a1-a2bf91434413
# ╟─3524e197-2629-4ee7-a1cb-54e34396a855
# ╟─1f6669aa-021b-4ae5-8037-0de5806e1a54
# ╟─0626a990-e862-4c92-9961-a09632c33fb0
# ╟─ac4a8d2e-411c-43d5-b7cc-46f4ef988c68
# ╟─135dac9b-0bd9-4e1d-90fb-7f2721f6fcc7