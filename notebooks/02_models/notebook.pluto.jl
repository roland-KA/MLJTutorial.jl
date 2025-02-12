### A Pluto.jl notebook ###
# v0.17.4

using Markdown
using InteractiveUtils

# ╔═╡ d09256dd-6c0d-4e28-9e54-3f7b3ca87ecb
begin
  	using CSV
  	using DataFrames
  	import Distributions
	using ScientificTypes
	using MLJ
	using MLJFlux
	using Plots
	using Tables
	using UrlDownload
  	using PlutoUI
end

# ╔═╡ a05a4f6d-c831-4fb1-9bca-7c69b794f8ce
html"""
<div style="
position: absolute;
width: calc(100% - 30px);
border: 50vw solid SteelBlue;
border-top: 500px solid SteelBlue;
border-bottom: none;
box-sizing: content-box;
left: calc(-50vw + 15px);
top: -500px;
height: 300px;
pointer-events: none;
"></div>

<div style="
height: 300px;
width: 100%;
background: SteelBlue;
color: #88BBD6;
padding-top: 68px;
padding-left: 5px;
">

<span style="
font-family: Vollkorn, serif;
font-weight: 700;
font-feature-settings: 'lnum', 'pnum';
"> 

<p style="
font-family: Alegreya sans;
font-size: 1.4rem;
font-weight: 300;
opacity: 1.0;
color: #CDCDCD;
">Tutorial - Part 2</p>
<p style="text-align: left; font-size: 2.5rem;">
Machine Learning in Julia
</p>
"""

# ╔═╡ 75003bf5-612e-4e32-aaf4-e53a77987b44
PlutoUI.TableOfContents(title = "MLJ Tutorial - Part 2")

# ╔═╡ bea73bf9-96c0-42fb-b795-033f6f2a0674
md"""
A workshop introducing the machine learning toolbox
[MLJ](https://alan-turing-institute.github.io/MLJ.jl/stable/).
"""

# ╔═╡ bc689638-fd19-4c9f-935f-ddf6a6bfbbdd
md"## Set-up"

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

# ╔═╡ 499cbc31-83ba-4583-ba1f-6363f43ec697
md"## General resources"

# ╔═╡ 2bac0883-5e62-4e1a-95ea-2955abd45275
md"""
- [List of methods introduced in this tutorial](methods.md)
- [MLJ Cheatsheet](https://alan-turing-institute.github.io/MLJ.jl/dev/mlj_cheatsheet/)
- [Common MLJ Workflows](https://alan-turing-institute.github.io/MLJ.jl/dev/common_mlj_workflows/)
- [MLJ manual](https://alan-turing-institute.github.io/MLJ.jl/dev/)
- [Data Science Tutorials in Julia](https://juliaai.github.io/DataScienceTutorials.jl/)
"""

# ╔═╡ 4afc3a94-c3e3-493e-b1b3-dd47e367ba54
md"# Part 2 - Selecting, Training and Evaluating Models"

# ╔═╡ ab471845-15a5-40f8-8d7e-8e449afd1c48
md"""
> **Goals:**
> 1. Search MLJ's database of model metadata to identify model candidates for a supervised learning task.
> 2. Evaluate the performance of a model on a holdout set using basic `fit!`/`predict` work-flow.
> 3. Inspect the outcomes of training and save these to a file.
> 3. Evaluate performance using other resampling strategies, such as cross-validation, in one line, using `evaluate!`
> 4. Plot a "learning curve", to inspect performance as a function of some model hyper-parameter, such as an iteration parameter
"""

# ╔═╡ cd60f13d-4311-421c-a29f-71ab1e29b06e
md"""
## The Iris Data Set
"""

# ╔═╡ 985baf9f-1507-442d-a949-7f3bd292fe31
md"""
The "Hello World!" of machine learning is to classify Fisher's
famous iris data set. This time, we'll grab the data from
[OpenML](https://www.openml.org):
"""

# ╔═╡ ae4f097b-4c18-4025-8514-99938a2932db
OpenML.describe_dataset(61)

# ╔═╡ 88c11aa3-2c4c-4200-a0de-1721c1bc2df2
begin
	irisData = OpenML.load(61); # a column dictionary table
	iris = DataFrames.DataFrame(irisData);
  	first(iris, 4)
end

# ╔═╡ 27b51025-5fc0-4453-bca8-7eec7950fd82
md"""
**Main goal.** To build and evaluate models for predicting the
`:class` variable, given the four remaining measurement variables.
"""

# ╔═╡ 3b869e8a-24c4-4b00-9873-1b1430e635cc
md"## Step 1. Inspect and fix scientific types"

# ╔═╡ 59e3c087-617d-457b-b43e-d0ebe87da176
schema(iris)

# ╔═╡ 93ee20a1-6db9-4157-b69e-cfdc0501fdc6
md"""
This schema fits well for our purposes, so there is nothing to fix here.

*Note*: In older versions MLJ/CategoricalArrays came up at this point with the scientifc types `Union{Missing,Continuous}` and `Union{Missing,Multiclass}`.  
Therefore the following coercion was necessary:

```julia
coerce!(iris,
  Union{Missing,Continuous} => Continuous,
  Union{Missing,Multiclass} => Multiclass)
```
"""

# ╔═╡ 992ca8fb-1a20-4664-abd3-cb77d7a79683
md"## Step 2. Split data into input and target parts"

# ╔═╡ bf7f99f5-7096-441f-879e-dc128f3db7b3
md"""
Here's how we split the data into target and input features, which
is needed for MLJ supervised models. We can randomize the data at the
same time:
"""

# ╔═╡ 933cc42f-6be5-4b9b-a367-9aa3c6cf34d0
yIris, XIris = unpack(iris, ==(:class), rng=123)

# ╔═╡ 8ad6eede-d717-4779-b8b2-fbca000635df
md"""
This puts the `:class` column into a vector `yIris`, and all remaining columns into a table `XIris`.
"""

# ╔═╡ f35ad4f4-2f4b-4a05-a9b5-48d93ef82b89
scitype(yIris)

# ╔═╡ b081e89d-3ded-4061-bf32-94657e65284e
md"""
Here's one way to access the documentation (at the REPL, `?unpack`
also works):
"""

# ╔═╡ 325b5554-5521-48da-9afd-65a5b5facac9
@doc unpack

# ╔═╡ 2f1d872a-8471-4e85-b6c8-54f5ed90a964
md"## On searching for a model"

# ╔═╡ ce0ec15e-a419-4517-9292-fe822525fc77
md"Here's how to see *all* models (not immediately useful):"

# ╔═╡ 95d1dc5f-75d9-4297-ae5e-4b83dcbc9675
all_models = models()

# ╔═╡ c2ce1680-24a7-4a9e-908f-d77bb7f9a509
md"""
If you already have an idea about the name of the model, you could search by string or regex:
"""

# ╔═╡ aa58b3e3-bdda-433a-9c3d-3b151b04c0c3
some_models = models("LinearRegressor")

# ╔═╡ d31909f8-f5f1-4773-8a29-32f11452654a
md"Each entry contains metadata for a model whose defining code is not yet loaded:"

# ╔═╡ c1f7376d-6f42-497f-a5f1-151fcbe229a2
meta = some_models[1]

# ╔═╡ 2640cb64-bc0e-4bca-81bc-2d5603785a09
targetscitype = meta.target_scitype

# ╔═╡ ba53ad4c-e092-40fd-9d87-1d1fbb0e3997
ScientificTypes.scitype(yIris) <: targetscitype

# ╔═╡ 5e706d1f-93f3-4d50-b950-fddef2a1fb10
md"So this model won't do. Let's  find all pure julia classifiers:"

# ╔═╡ 7de5633e-8d59-4ad8-951b-64cb2a36c8e3
filter_julia_classifiers(meta) =
      AbstractVector{Finite} <: meta.target_scitype &&
      meta.is_pure_julia

# ╔═╡ 2eb78823-0a9b-436d-b723-723d7e329376
models(filter_julia_classifiers)

# ╔═╡ a42a2993-098f-4943-a87d-950c50fb2955
md"Find all (supervised) models that match my data!"

# ╔═╡ db2d9ba2-1fc4-4a7f-8448-4bcb089096cd
models(matching(XIris, yIris))

# ╔═╡ 34feba2c-e700-423a-a012-a84240254fb6
md"## Step 3. Select and instantiate a model"

# ╔═╡ ad6637a0-b5f3-430c-bbdd-9799f7bb2e60
md"To load the code defining a new model type we use the `@load` macro:"

# ╔═╡ 622d0b24-ca8f-4bd4-97a7-88e3af4f10ee
NeuralNetworkClassifier = @load NeuralNetworkClassifier

# ╔═╡ b98100f5-976f-4d6a-b372-8c9866e51852
md"""
Other ways to load model code are described
[here](https://alan-turing-institute.github.io/MLJ.jl/dev/loading_model_code/#Loading-Model-Code).
"""

# ╔═╡ 984397e2-ab08-4ef5-8f3d-b82f1e7b6f7a
md"""
We'll instantiate this type with default values for the
hyperparameters:
"""

# ╔═╡ 335d13dc-807d-491f-ab04-579e5608ae53
model = NeuralNetworkClassifier()

# ╔═╡ 96cba2ba-f64e-44a7-86cf-35420d9e6995
info(model)

# ╔═╡ e1e8e176-74da-437a-a29a-8d0445351914
md"""
In MLJ a *model* is just a struct containing hyper-parameters, and
that's all. A model does not store *learned* parameters. Models are
mutable:
"""

# ╔═╡ 83b4291e-3842-4819-be65-28d0fcca50a8
model.epochs = 12

# ╔═╡ 9a1e2ea6-4e31-49d5-9a2e-c468345d87d1
md"""
And all models have a key-word constructor that works once `@load`
has been performed:
"""

# ╔═╡ af0c0a55-d994-452d-b5fa-cb79ebf595ef
NeuralNetworkClassifier(epochs=12) == model

# ╔═╡ 39a680a3-2e87-4b48-91c5-524da38aa391
md"## On fitting, predicting, and inspecting models"

# ╔═╡ 99cb052f-c512-4040-8c47-b070474202aa
md"""
### The basic workflow
"""

# ╔═╡ 595983b4-3c4e-44af-ad90-b4405b216771
md"""
In MLJ a model and training/validation data are typically bound
together in a machine:
"""

# ╔═╡ 72510848-3148-408a-895b-997a92b731e0
mach = machine(model, XIris, yIris)

# ╔═╡ c8700a21-e95b-4f0f-a525-e9b04a4bd246
md"""
A machine stores *learned* parameters, among other things. We'll
train this machine on 70% of the data and evaluate on a 30% holdout
set. Let's start by dividing all row indices into `train` and `test`
subsets:
"""

# ╔═╡ 5b8d30eb-bd5c-4b09-80f0-ba7781e173cf
train, test = partition(1:length(yIris), 0.7)

# ╔═╡ a232a792-8692-45cc-9cbc-9a2c39793333
md"Now we can `fit!`..."

# ╔═╡ 62be4fb6-3b7e-4b80-b887-2b16710e5502
fit!(mach, rows=train, verbosity=2)

# ╔═╡ 3856cc2d-ea15-4077-9452-5298a8a4a401
md"... and `predict`:"

# ╔═╡ 10b7acb8-1a3b-4dca-9f5e-a712a2f8a988
yhat = predict(mach, rows=test);  # or `predict(mach, Xnew)`

# ╔═╡ 5a86fd44-8e9b-4694-b017-96f1602f2cad
yhat[1:3]

# ╔═╡ 7d8e68c8-430c-46dd-8be2-2a4017c45345
md"We'll have more to say on the form of this prediction shortly."

# ╔═╡ fb9a3a2d-6b1a-4d64-a7ad-80d84f5b0070
md"After training, one can inspect the learned parameters:"

# ╔═╡ deef14fe-9822-4fa8-8378-5aa686f0b407
fitted_params(mach)

# ╔═╡ d5308047-a4ee-41c8-9f43-49763e8691a1
md"""
Everything else the user might be interested in is accessed from the
training *report*:
"""

# ╔═╡ d8f73aeb-2b82-4afd-bb0e-3a45761c733a
report(mach)

# ╔═╡ 4d01b5f6-96bd-4d4d-bc5b-ef1078e2822f
md"""
### Save and retrieve a machine
"""

# ╔═╡ 2ecd9ccb-45c4-4de4-9979-7044b2f2df33
md"You save a machine like this:"

# ╔═╡ 43887c78-378f-4bb8-b2a1-fbbde543f620
MLJ.save("neural_net.jlso", mach)

# ╔═╡ 43c25729-4bda-4c21-910b-f8a9a217eff2
md"And retrieve it like this:"

# ╔═╡ de239414-32a8-4691-aa36-d2e8546da46a
begin
  mach2 = machine("neural_net.jlso")
  yhat2 = predict(mach2, XIris);
  yhat2[1:3]
end

# ╔═╡ 2a1d3e22-d17c-452d-88a1-a2bf91434413
md"If you want to fit a retrieved model, you will need to bind some data to it:"

# ╔═╡ ef2282bc-db28-4d54-a1cb-54e34396a855
begin
  mach3 = machine("neural_net.jlso", XIris, yIris)
  fit!(mach3)
end

# ╔═╡ 189c145c-17c5-4532-9cfb-0ec415e913ed
md"""
!!! note 

	The last two cells may report an EOF error on the first run of the notebook. This can be solved by just re-executing the `MLJ.save` command above and then two cells which read the saved machine.
"""

# ╔═╡ b5918685-f6f7-49fd-8f4c-cb29f1b270ce
md"""
### Warm restart
"""

# ╔═╡ 9dbeeed8-d882-4e04-8037-0de5806e1a54
md"""
Machines remember the last set of hyper-parameters used during fit,
which, in the case of iterative models, allows for a warm restart of
computations in the case that only the iteration parameter is
increased:
"""

# ╔═╡ 7547798a-24c9-4c5f-9961-a09632c33fb0
with_terminal() do
  model.epochs = model.epochs + 4
  fit!(mach, rows=train, verbosity=2)
end

# ╔═╡ 8ce96a51-938d-43d1-b7cc-46f4ef988c68
md"""
For this particular model we can also increase `:learning_rate`
without triggering a cold restart:
"""

# ╔═╡ 04255053-ed5f-48d6-90fb-7f2721f6fcc7
with_terminal() do
  model.epochs = model.epochs + 4
  model.optimiser.eta = 10 * model.optimiser.eta
  fit!(mach, rows=train, verbosity=2)
end

# ╔═╡ 35af5a52-69f9-4b74-af65-ccd25ecb9818
md"""
However, change any other parameter and training will restart from
scratch:
"""

# ╔═╡ 55531d1d-31e9-4e61-8890-979691212d9b
with_terminal() do
  model.lambda = 0.001
  fit!(mach, rows=train, verbosity=2)
end

# ╔═╡ 87065854-efb2-44b7-a6fa-eaf14df5d44b
md"""
Iterative models that implement warm-restart for training can be
controlled externally (eg, using an out-of-sample stopping
criterion). See
[here](https://alan-turing-institute.github.io/MLJ.jl/dev/controlling_iterative_models/)
for details.
"""

# ╔═╡ e7472876-9209-4408-8f46-f6380fb9860b
md"""
### Probabilistic predictions
"""

# ╔═╡ 925a7014-51dc-4a55-8025-5084804a9f6c
md"""
Let's train silently for a total of 50 epochs, and look at a
prediction:
"""

# ╔═╡ df4bd436-9b0e-484b-9e90-09023d201062
begin
  model.epochs = 50
  fit!(mach, rows=train)
  yhat3 = predict(mach, XIris[test,:]); # or predict(mach, rows=test)
  yhat3[1]
end

# ╔═╡ 2faf541c-1a2c-4274-b7bb-2f33ef765cc0
md"What's going on here?"

# ╔═╡ ca444411-88c0-4c2c-9625-01172c4a0081
info(model).prediction_type

# ╔═╡ 49bcdff9-0e08-45e3-af4f-11c7de9e21dd
md"""
**Important**:
- In MLJ, a model that can predict probabilities (and not just point values) will do so by default.
- For most probabilistic predictors, the predicted object is a `Distributions.Distribution` object (supporting the `Distributions.jl` [API](https://juliastats.org/Distributions.jl/latest/extends/#Create-a-Distribution-1)) or a `CategoricalDistributions.UnivariateFinite` object (the case here), which all support the follwing methods: `rand`,  `pdf`, `logpdf`; and, where appropriate: `mode`, `median` and `mean`.
"""

# ╔═╡ 9653dbb8-a168-4a07-8dba-241d9b744683
md"""
So, to obtain the probability of "Iris-virginica" in the first test
prediction, we do
"""

# ╔═╡ 1613d417-80ac-40bd-a6e5-2f0b4dca5c59
pdf(yhat3[1], "Iris-virginica")

# ╔═╡ b760d242-43de-4248-8550-20498aa03ed0
md"To get the most likely observation, we do"

# ╔═╡ f40a1541-ee37-487e-9e7b-5b943cf6b560
mode(yhat3[1])

# ╔═╡ 523bcb12-f95d-4b90-bce6-0a1379cc1259
md"These can be broadcast over multiple predictions in the usual way:"

# ╔═╡ 691b9fb3-72c7-43bd-9608-b5032c116833
broadcast(pdf, yhat3[1:4], "Iris-versicolor")

# ╔═╡ 880f9d8d-3095-45b5-b473-4aa968e6937a
mode.(yhat3[1:4])

# ╔═╡ 275f2017-5520-4072-8d9e-644a1b3cc6b6
md"""
Or, alternatively, you can use the `predict_mode` operation instead
of `predict`:
"""

# ╔═╡ 93533a8e-e507-4950-ac0a-23ded81445da
predict_mode(mach, XIris[test,:])[1:4] # or predict_mode(mach, rows=test)[1:4]

# ╔═╡ 1d455c06-389b-402a-8535-1a088a6a3228
md"For a more conventional matrix of probabilities you can do this:"

# ╔═╡ 91b6e632-f1be-4b1f-8af9-a6bf29a06338
L = levels(yIris)

# ╔═╡ 76bc1d1e-3de7-461c-a39f-7893c73eef39
pdf(yhat3, L)[1:4, :]

# ╔═╡ bf534937-b3c5-4e01-bcca-51a27994a151
md"""
However, in a typical MLJ work-flow, this is not as useful as you
might imagine. In particular, all probabilistic performance measures
in MLJ expect distribution objects in their first slot:
"""

# ╔═╡ 8d59229c-1a70-40b2-9b33-09b4b6661170
cross_entropy(yhat3, yIris[test]) |> mean

# ╔═╡ 8b98a48c-d2c6-4ecf-b45d-88d068bb0fa2
md"To apply a deterministic measure, we first need to obtain point-estimates:"

# ╔═╡ 0fb6fa7a-f0c0-4926-92c8-6db3a590d963
misclassification_rate(mode.(yhat3), yIris[test])

# ╔═╡ 09a60a33-8b8d-4aed-abf5-96f457eb2bdf
md"""
We note in passing that there is also a search tool for measures
analogous to `models`:
"""

# ╔═╡ e08d911c-f1a4-40b5-8a60-2e0214c059f5
measures()

# ╔═╡ 8323c2ea-16bc-4913-a38a-beb5c7157b57
md"## Step 4. Evaluate the model performance"

# ╔═╡ b2227a29-b214-4683-81f5-507803ea9ed6
md"""
Naturally, MLJ provides boilerplate code for carrying out a model
evaluation with a lot less fuss. Let's repeat the performance
evaluation above and add an extra measure, `brier_score`:
"""

# ╔═╡ c63ed6db-6d2a-4ee7-9b21-6d4eb642d87e
evaluate!(mach, resampling=Holdout(fraction_train=0.7),
          measures=[cross_entropy, misclassification_rate, brier_score])

# ╔═╡ f829c00b-f082-4ec4-b98c-3df1f31879bf
md"Or applying cross-validation instead:"

# ╔═╡ 727ecfae-2e87-4e05-92b7-4ceba56e97ad
evaluate!(mach, resampling=CV(nfolds=6),
          measures=[cross_entropy, misclassification_rate, brier_score])

# ╔═╡ 31359fe0-8d95-4740-b122-214de244406c
md"""
Or, Monte Carlo cross-validation (cross-validation repeated
randomized folds)
"""

# ╔═╡ 1383b285-59f2-4652-8a4b-c83694978e38
e = evaluate!(mach, resampling=CV(nfolds=6, rng=123),
              repeats=3,
              measures=[cross_entropy, misclassification_rate, brier_score])

# ╔═╡ 3c3b7c0f-ef92-4eeb-a8b6-f7ff516dedc4
md"""
One can access the following properties of the output `e` of an
evaluation: `measure`, `measurement`, `per_fold` (measurement for
each fold) and `per_observation` (measurement per observation, if
reported).
"""

# ╔═╡ a6725314-8f98-4869-81e1-74ef03c2e79e
md"""
We finally note that you can restrict the rows of observations from
which train and test folds are drawn, by specifying `rows=...`. For
example, imagining the last 30% of target observations are `missing`
you might have a work-flow like this:
"""

# ╔═╡ 174b9a92-2cf5-4630-a04e-0b76409c14a7
let
  train, test = partition(eachindex(yIris), 0.7)
  mach = machine(model, XIris, yIris)
  evaluate!(mach, resampling = CV(nfolds = 6),
            measures = [cross_entropy, misclassification_rate, brier_score],
            rows = train)     # cv estimate, resampling from `train`
  fit!(mach, rows = train)    # re-train using all of `train` observations
  predict(mach, rows = test); # and predict missing targets
end

# ╔═╡ 51f56327-7309-4aa2-b979-3458f2f26667
md"## On learning curves"

# ╔═╡ f2becd33-0b66-4b13-97e3-6677afc6ca9f
md"""
Since our model is an iterative one, we might want to inspect the
out-of-sample performance as a function of the iteration
parameter. For this we can use the `learning_curve` function (which,
incidentally can be applied to any model hyper-parameter). This
starts by defining a one-dimensional range object for the parameter
(more on this when we discuss tuning in Part 4):
"""

# ╔═╡ 1d65816d-d818-434d-b10e-562ce21caa04
r = range(model, :epochs, lower=1, upper=50, scale=:log10)

# ╔═╡ 91cefb80-4c5b-4a1a-837b-47e9cebfb913
curve = learning_curve(mach,
                    	range = r,
                        resampling = Holdout(fraction_train = 0.7), # (default)
                        measure = cross_entropy)

# ╔═╡ 97400000-e067-4c66-8f78-ab549ef1544e
begin  
  gr(size=(490,300))
  plt = plot(curve.parameter_values, curve.measurements, leg = false)
  xlabel!(plt, "epochs")
  ylabel!(plt, "cross entropy on holdout set")
  savefig("learning_curve.png")
  plt
end

# ╔═╡ e80b6400-2c9e-4198-a8a4-a53f5149481e
md"We will return to learning curves when we look at tuning in Part 4."

# ╔═╡ fc268355-011e-44d5-8704-dbab8e09b4f1
md"# Resources for Part 2"

# ╔═╡ 25164534-5e28-44f4-a02f-27b6c05e4d02
md"""
- From the MLJ manual:
    - [Getting Started](https://alan-turing-institute.github.io/MLJ.jl/dev/getting_started/)
    - [Model Search](https://alan-turing-institute.github.io/MLJ.jl/dev/model_search/)
    - [Evaluating Performance](https://alan-turing-institute.github.io/MLJ.jl/dev/evaluating_model_performance/) (using `evaluate!`)
    - [Learning Curves](https://alan-turing-institute.github.io/MLJ.jl/dev/learning_curves/)
    - [Performance Measures](https://alan-turing-institute.github.io/MLJ.jl/dev/performance_measures/) (loss functions, scores, etc)
- From Data Science Tutorials:
    - [Choosing and evaluating a model](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/choosing-a-model/)
    - [Fit, predict, transform](https://juliaai.github.io/DataScienceTutorials.jl/getting-started/fit-and-predict/)
"""

# ╔═╡ 1ffaccf9-a0ec-451c-bea4-3d467d48781c
md"# Exercises for Part 2"

# ╔═╡ 14a71476-a7ca-4324-97c5-2979af8a507d
md"## Exercise 4"

# ╔═╡ 47c32a4a-5596-4970-b639-63c76c72c513
md"""
(a) Identify all supervised MLJ models that can be applied (without
type coercion or one-hot encoding) to a supervised learning problem
with input features `X4` and target `y4` defined below:
"""

# ╔═╡ 9a75c053-59ba-4c53-8f5a-e1ee9eb5c15c
begin
  poisson = Distributions.Poisson
  
  age = 18 .+ 60  * rand(10);
  salary = coerce(rand(["small", "big", "huge"], 10), OrderedFactor);
  levels!(salary, ["small", "big", "huge"]);
  small = salary[1]
end

# ╔═╡ f3de7b01-d9e5-4b5c-adc5-e671db8bca5d
begin
  X4 = DataFrames.DataFrame(age=age, salary=salary)
  
  n_devices(salary) = salary > small ? rand(poisson(1.3)) : rand(poisson(2.9))
  y4 = [n_devices(row.salary) for row in eachrow(X4)]
end

# ╔═╡ 158df0a8-625f-4389-86f1-0ea38de21abb
md"""
(b) What models can be applied if you coerce the salary to a
`Continuous` scitype?
"""

# ╔═╡ 0cec3967-8a9e-4da5-a55c-0cb44ab816d7
md"## Exercise 5 (unpack)"

# ╔═╡ 1dcadbe8-6897-48bb-be86-92ecfd0d2343
md"After evaluating the following ..."

# ╔═╡ f303e667-6485-4949-9cf1-facf39e3f302
data = (a = [1, 2, 3, 4],
    	b = rand(4),
        c = rand(4),
        d = coerce(["male", "female", "female", "male"], OrderedFactor))

# ╔═╡ a1c60d89-5d61-4a26-b61c-748aec38e674
y5, X5, w = unpack(data,
                   ==(:a),
                   name -> elscitype(Tables.getcolumn(data, name)) == Continuous);

# ╔═╡ b5b23e79-35ce-4857-9727-ed822e4fd85d
md"...attempt to guess the evaluations of the following (uncomment to see the results):"

# ╔═╡ 8346cbaa-16bb-4f7a-b2f2-e08965e5be66
# y5

# ╔═╡ b4ecc31b-4105-4a38-aff1-7de2c05d16f0
# X5

# ╔═╡ 76dc6ac8-03fe-4c6e-a543-f9324a87efad
# w

# ╔═╡ 0860f65e-8e80-4394-8657-9fba0caf3cb7
md"## Exercise 6 (first steps in modeling Horse Colic)"

# ╔═╡ 17b6bf6e-31d0-4981-a217-e58f442fc85c
md"""
Here is the Horse Colic data introduced in Part 1, together with the
type coercions we performed there:
"""

# ╔═╡ 6df9f266-f9d9-4506-b8ad-0340f15a03ba
begin
  csv_file = urldownload("https://raw.githubusercontent.com/ablaom/"*
                     "MachineLearningInJulia2020/"*
                     "for-MLJ-version-0.16/data/horse.csv");
  horse = DataFrames.DataFrame(csv_file); # convert to data frame
  coerce!(horse, autotype(horse));
  coerce!(horse, Count => Continuous);
  coerce!(horse,
          :surgery               => Multiclass,
          :age                   => Multiclass,
          :mucous_membranes      => Multiclass,
          :capillary_refill_time => Multiclass,
          :outcome               => Multiclass,
          :cp_data               => Multiclass);
  schema(horse)
end

# ╔═╡ 0afa73e6-f371-4b04-946d-b124a8db5f7c
md"""
(a) Suppose we want to use predict the `:outcome` variable, based on
the remaining variables that are `Continuous` (one-hot encoding
categorical variables is discussed later in Part 3) *while ignoring
the others*.  Extract from the `horse` data set (defined in Part 1)
appropriate input features `X` and target variable `y`. (Do not,
however, randomize the observations.)
"""

# ╔═╡ fed7482b-707f-46f0-b582-dfcbeb05bcc5
md"""
(b) Create a 70:30 `train`/`test` split of the data and train a
`LogisticClassifier` model, from the `MLJLinearModels` package, on
the `train` rows. Use `lambda=100` and default values for the
other hyper-parameters. (Although one would normally standardize
(whiten) the continuous features for this model, do not do so here.)
After training:
- (i) Recalling that a logistic classifier (aka logistic regressor) is
  a linear-based model learning a *vector* of coefficients for each
  feature (one coefficient for each target class), use the
  `fitted_params` method to find this vector of coefficients in the
  case of the `:pulse` feature. (You can convert a vector of pairs `v =
  [x1 => y1, x2 => y2, ...]` into a dictionary with `Dict(v)`.)
- (ii) Evaluate the `cross_entropy` performance on the `test`
  observations. 
-  $\star$ (iii) In how many `test` observations does the predicted
  probability of the observed class exceed 50%?
- (iv) Find the `misclassification_rate` in the `test`
  set. (*Hint.* As this measure is deterministic, you will either
  need to broadcast `mode` or use `predict_mode` instead of
  `predict`.)
"""

# ╔═╡ 84ccf4c1-e3c5-4d25-806e-1bc580dc349d
md"""
(c) Instead use a `RandomForestClassifier` model from the
    `DecisionTree` package and:

- (i) Generate an appropriate learning curve to convince yourself
  that out-of-sample estimates of the `cross_entropy` loss do not
  substantially improve for `n_trees > 50`. Use default values for
  all other hyper-parameters, and feel free to use all available
  data to generate the curve.
- (ii) Fix `n_trees=90` and use `evaluate!` to obtain a 9-fold
  cross-validation estimate of the `cross_entropy`, restricting
  sub-sampling to the `train` observations.
- (iii) Now use *all* available data but set
  `resampling=Holdout(fraction_train=0.7)` to obtain a score you can
  compare with the `KNNClassifier` in part (b)(iii). Which model is
  better?
"""

# ╔═╡ c2cda2eb-6110-4b1f-93d8-53c527b0a48c
html"<a id='part-3-transformers-and-pipelines'></a>"

# ╔═╡ 135dac9b-0bd9-4e1d-af98-8dffdf3118fc
md"""
---

*This notebook was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
MLJ = "add582a8-e3ab-11e8-2d5e-e98b27df1bc7"
MLJFlux = "094fc8d1-fd35-5302-93ea-dabda2abf845"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ScientificTypes = "321657f4-b219-11e9-178b-2701a2544e81"
Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
UrlDownload = "856ac37a-3032-4c1c-9122-f86d88358c8b"

[compat]
CSV = "~0.9.11"
DataFrames = "~1.3.1"
Distributions = "~0.25.37"
MLJ = "~0.17.0"
MLJFlux = "~0.2.6"
Plots = "~1.25.4"
PlutoUI = "~0.7.27"
ScientificTypes = "~3.0.0"
Tables = "~1.6.1"
UrlDownload = "~1.0.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ARFFFiles]]
deps = ["CategoricalArrays", "Dates", "Parsers", "Tables"]
git-tree-sha1 = "e8c8e0a2be6eb4f56b1672e46004463033daa409"
uuid = "da404889-ca92-49ff-9e8b-0aa6b4d38dc8"
version = "1.4.1"

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "1ee88c4c76caa995a885dc2f22a5d548dfbbc0ba"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.2.2"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random", "Test"]
git-tree-sha1 = "a598ecb0d717092b5539dbbe890c98bac842b072"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.2.0"

[[BSON]]
git-tree-sha1 = "ebcd6e22d69f21249b7b8668351ebf42d6dc87a1"
uuid = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0"
version = "0.3.4"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CompilerSupportLibraries_jll", "ExprTools", "GPUArrays", "GPUCompiler", "LLVM", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "SpecialFunctions", "TimerOutputs"]
git-tree-sha1 = "429a1a05348ce948a96adbdd873fbe6d9e5e052f"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "3.6.2"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "c308f209870fdbd84cb20332b6dfaf14bf3387f8"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.2"

[[CategoricalDistributions]]
deps = ["CategoricalArrays", "Distributions", "Missings", "OrderedCollections", "Random", "ScientificTypesBase", "UnicodePlots"]
git-tree-sha1 = "a5734a58e5dc8c749b5507d03ba5e457d077181b"
uuid = "af321ab8-2d2e-40a6-b165-3d674595d28e"
version = "0.1.4"

[[ChainRules]]
deps = ["ChainRulesCore", "Compat", "LinearAlgebra", "Random", "RealDot", "Statistics"]
git-tree-sha1 = "c6366ec79d9e62cd11030bba0945712eb4013712"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.17.0"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "926870acb6cbcf029396f2f2de030282b6bc1941"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.11.4"

[[ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "a851fec56cb73cfdf43762999ec72eff5b86882a"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.15.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "b618084b49e78985ffa8422f32b9838e397b9fc2"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.0"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "cfdfef912b7f93e4b848e80b9befdf9e331bc05a"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.1"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[DiffRules]]
deps = ["LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "9bc5dac3c8b6706b58ad5ce24cffd9861f07c94f"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.9.0"

[[Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "6a8dc9f82e5ce28279b6e3e2cea9421154f5bd0d"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.37"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[EarlyStopping]]
deps = ["Dates", "Statistics"]
git-tree-sha1 = "98fdf08b707aaf69f524a6cd0a67858cefe0cfb6"
uuid = "792122b4-ca99-40de-a6bc-6742525f08b6"
version = "0.3.0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[ExprTools]]
git-tree-sha1 = "b7e3d17636b348f005f11040025ae8c6f645fe92"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.6"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "04d13bfa8ef11720c24e4d840c0033d145537df7"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.17"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Flux]]
deps = ["AbstractTrees", "Adapt", "ArrayInterface", "CUDA", "CodecZlib", "Colors", "DelimitedFiles", "Functors", "Juno", "LinearAlgebra", "MacroTools", "NNlib", "NNlibCUDA", "Pkg", "Printf", "Random", "Reexport", "SHA", "SparseArrays", "Statistics", "StatsBase", "Test", "ZipFile", "Zygote"]
git-tree-sha1 = "e8b37bb43c01eed0418821d1f9d20eca5ba6ab21"
uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c"
version = "0.12.8"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "2b72a5624e289ee18256111657663721d59c143e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.24"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Functors]]
git-tree-sha1 = "e4768c3b7f597d5a352afa09874d16e3c3f6ead2"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.7"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "0c603255764a1fa0b61752d2bec14cfbd18f7fe8"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+1"

[[GPUArrays]]
deps = ["Adapt", "LinearAlgebra", "Printf", "Random", "Serialization", "Statistics"]
git-tree-sha1 = "d9681e61fbce7dde48684b40bdb1a319c4083be7"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.1.3"

[[GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "2cac236070c2c4b36de54ae9146b55ee2c34ac7a"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.13.10"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "b9a93bcdf34618031891ee56aad94cfff0843753"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.63.0"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f97acd98255568c3c9b416c5a3cf246c1315771b"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.63.0+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IRTools]]
deps = ["InteractiveUtils", "MacroTools", "Test"]
git-tree-sha1 = "006127162a51f0effbdfaab5ac0c83f8eb7ea8f3"
uuid = "7869d1d1-7146-5819-86e3-90919afe41df"
version = "0.4.4"

[[IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "8d70835a3759cdd75881426fced1508bb7b7e1b6"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.1"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[IterationControl]]
deps = ["EarlyStopping", "InteractiveUtils"]
git-tree-sha1 = "83c84b7b87d3063e48a909a86c3c5bf4c3521962"
uuid = "b3c1a2ee-3fec-4384-bf48-272ea71de57c"
version = "0.5.2"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JLSO]]
deps = ["BSON", "CodecZlib", "FilePathsBase", "Memento", "Pkg", "Serialization"]
git-tree-sha1 = "e00feb9d56e9e8518e0d60eef4d1040b282771e2"
uuid = "9da8a3cd-07a3-59c0-a743-3fdc52c30d11"
version = "2.6.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Printf", "Unicode"]
git-tree-sha1 = "7cc22e69995e2329cc047a879395b2b74647ab5f"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "4.7.0"

[[LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c5fc4bef251ecd37685bea1c4068a9cfa41e8b9a"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.13+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a8f4f279b6fa3c3c4f1adadd78a621b13a506bce"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.9"

[[LatinHypercubeSampling]]
deps = ["Random", "StableRNGs", "StatsBase", "Test"]
git-tree-sha1 = "42938ab65e9ed3c3029a8d2c58382ca75bdab243"
uuid = "a5e1c1ea-c99a-51d3-a14d-a9a37257b02d"
version = "1.8.0"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LearnBase]]
git-tree-sha1 = "a0d90569edd490b82fdc4dc078ea54a5a800d30a"
uuid = "7f8f8fb0-2700-5f03-b4bd-41f8cfc144b6"
version = "0.4.1"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "e5718a00af0ab9756305a0392832c8952c7426c1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.6"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[LossFunctions]]
deps = ["InteractiveUtils", "LearnBase", "Markdown", "RecipesBase", "StatsBase"]
git-tree-sha1 = "0f057f6ea90a84e73a8ef6eebb4dc7b5c330020f"
uuid = "30fc2ffe-d236-52d8-8643-a9d8f7c094a7"
version = "0.7.2"

[[MLJ]]
deps = ["CategoricalArrays", "ComputationalResources", "Distributed", "Distributions", "LinearAlgebra", "MLJBase", "MLJEnsembles", "MLJIteration", "MLJModels", "MLJSerialization", "MLJTuning", "OpenML", "Pkg", "ProgressMeter", "Random", "ScientificTypes", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "3b4ebc5023cc039c65a1089e6d8c248a9b96dfd1"
uuid = "add582a8-e3ab-11e8-2d5e-e98b27df1bc7"
version = "0.17.0"

[[MLJBase]]
deps = ["CategoricalArrays", "CategoricalDistributions", "ComputationalResources", "Dates", "DelimitedFiles", "Distributed", "Distributions", "InteractiveUtils", "InvertedIndices", "LinearAlgebra", "LossFunctions", "MLJModelInterface", "Missings", "OrderedCollections", "Parameters", "PrettyTables", "ProgressMeter", "Random", "ScientificTypes", "StatisticalTraits", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "54cae1f0bde7bbc72fe7ff42353b7880347bd0d5"
uuid = "a7f614a8-145f-11e9-1d2a-a57a1082229d"
version = "0.19.2"

[[MLJEnsembles]]
deps = ["CategoricalArrays", "CategoricalDistributions", "ComputationalResources", "Distributed", "Distributions", "MLJBase", "MLJModelInterface", "ProgressMeter", "Random", "ScientificTypesBase", "StatsBase"]
git-tree-sha1 = "4279437ccc8ece8f478ded5139334b888dcce631"
uuid = "50ed68f4-41fd-4504-931a-ed422449fee0"
version = "0.2.0"

[[MLJFlux]]
deps = ["CategoricalArrays", "ColorTypes", "ComputationalResources", "Flux", "MLJModelInterface", "ProgressMeter", "Random", "Statistics", "Tables"]
git-tree-sha1 = "ecfc181ded92f12396886291946837328045d235"
uuid = "094fc8d1-fd35-5302-93ea-dabda2abf845"
version = "0.2.6"

[[MLJIteration]]
deps = ["IterationControl", "MLJBase", "Random"]
git-tree-sha1 = "5f32c3d281904d6e5fc64250f55732d4b24014de"
uuid = "614be32b-d00c-4edb-bd02-1eb411ab5e55"
version = "0.4.1"

[[MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "7ffdd75b2b13d1ec8640bfe80ab81bb158910a1d"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.3.5"

[[MLJModels]]
deps = ["CategoricalArrays", "CategoricalDistributions", "Dates", "Distances", "Distributions", "InteractiveUtils", "LinearAlgebra", "MLJModelInterface", "OrderedCollections", "Parameters", "Pkg", "PrettyPrinting", "REPL", "Random", "Requires", "ScientificTypes", "StatisticalTraits", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "cecd98731368f1eb46634d1476f49332560f886f"
uuid = "d491faf4-2d78-11e9-2867-c94bc002c0b7"
version = "0.15.1"

[[MLJSerialization]]
deps = ["IterationControl", "JLSO", "MLJBase", "MLJModelInterface"]
git-tree-sha1 = "cc5877ad02ef02e273d2622f0d259d628fa61cd0"
uuid = "17bed46d-0ab5-4cd4-b792-a5c4b8547c6d"
version = "1.1.3"

[[MLJTuning]]
deps = ["ComputationalResources", "Distributed", "Distributions", "LatinHypercubeSampling", "MLJBase", "ProgressMeter", "Random", "RecipesBase"]
git-tree-sha1 = "a443cc088158b949876d7038a1aa37cfc8c5509b"
uuid = "03970b2e-30c4-11ea-3135-d1576263f10f"
version = "0.6.16"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[Memento]]
deps = ["Dates", "Distributed", "Requires", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "9b0b0dbf419fbda7b383dc12d108621d26eeb89f"
uuid = "f28f55f0-a522-5efc-85c2-fe41dfb9b2d9"
version = "1.3.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "2eb305b13eaed91d7da14269bf17ce6664bfee3d"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.7.31"

[[NNlibCUDA]]
deps = ["CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics"]
git-tree-sha1 = "a2dc748c9f6615197b6b97c10bcce829830574c9"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.1.11"

[[NaNMath]]
git-tree-sha1 = "f755f36b19a5116bb580de457cda0c140153f283"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.6"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[OpenML]]
deps = ["ARFFFiles", "HTTP", "JSON", "Markdown", "Pkg"]
git-tree-sha1 = "06080992e86a93957bfe2e12d3181443cedf2400"
uuid = "8b6db2d4-7670-4922-a472-f9537c81ab66"
version = "0.2.0"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "d7fa6237da8004be601e19bd6666083056649918"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.3"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "68604313ed59f0408313228ba09e79252e4b2da8"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.1.2"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "71d65e9242935132e71c4fbf084451579491166a"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.25.4"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "fed057115644d04fba7f4d768faeeeff6ad11a60"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.27"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[PrettyPrinting]]
git-tree-sha1 = "a5db8a42938bc65c2679406c51a8f5fe9597c6e7"
uuid = "54e16d92-306c-5ea0-a30b-337be88ac337"
version = "0.3.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Random123]]
deps = ["Libdl", "Random", "RandomNumbers"]
git-tree-sha1 = "0e8b146557ad1c6deb1367655e052276690e71a3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.4.2"

[[RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "7ad0dfa8d03b7bcf8c597f59f5292801730c55b8"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.4.1"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "8f82019e525f4d5c669692772a6f4b0a58b06a6a"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.2.0"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[ScientificTypes]]
deps = ["CategoricalArrays", "ColorTypes", "Dates", "Distributions", "PrettyTables", "Reexport", "ScientificTypesBase", "StatisticalTraits", "Tables"]
git-tree-sha1 = "ba70c9a6e4c81cc3634e3e80bb8163ab5ef57eb8"
uuid = "321657f4-b219-11e9-178b-2701a2544e81"
version = "3.0.0"

[[ScientificTypesBase]]
git-tree-sha1 = "a8e18eb383b5ecf1b5e6fc237eb39255044fd92b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "3.0.0"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "244586bc07462d22aed0113af9c731f2a518c93e"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.10"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e08890d19787ec25029113e88c34ec20cac1c91e"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.0.0"

[[StableRNGs]]
deps = ["Random", "Test"]
git-tree-sha1 = "3be7d49667040add7ee151fefaf1f8c04c8c8276"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.0"

[[Static]]
deps = ["IfElse"]
git-tree-sha1 = "7f5a513baec6f122401abfc8e9c074fdac54f6c1"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.4.1"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "de9e88179b584ba9cf3cc5edbb7a41f26ce42cda"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.0"

[[StatisticalTraits]]
deps = ["ScientificTypesBase"]
git-tree-sha1 = "271a7fea12d319f23d55b785c51f6876aadb9ac0"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "3.0.0"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "d88665adc9bcf45903013af0982e2fd05ae3d0a6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "51383f2d367eb3b444c961d485c565e4c0cf4ba0"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.14"

[[StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "bedb3e17cc1d94ce0e6e66d3afa47157978ba404"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.14"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "2ce41e0d042c60ecd131e9fb7154a3bfadbf50d3"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.3"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "7cb456f358e8f9d102a8b25e8dfedf58fa5689bc"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.13"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[UnicodePlots]]
deps = ["Crayons", "Dates", "SparseArrays", "StatsBase"]
git-tree-sha1 = "3cb994143aba28cfe66615702505b2d294cebd3e"
uuid = "b8865327-cd53-5732-bb35-84acbb429228"
version = "2.5.1"

[[Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[UrlDownload]]
deps = ["HTTP", "ProgressMeter"]
git-tree-sha1 = "05f86730c7a53c9da603bd506a4fc9ad0851171c"
uuid = "856ac37a-3032-4c1c-9122-f86d88358c8b"
version = "1.0.0"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "66d72dc6fcc86352f01676e8f0f698562e60510f"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.23.0+0"

[[WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "c69f9da3ff2f4f02e811c3323c22e5dfcb584cfa"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.1"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "IRTools", "InteractiveUtils", "LinearAlgebra", "MacroTools", "NaNMath", "Random", "Requires", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "78da1a0a69bcc86b33f7cb07bc1566c926412de3"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.33"

[[ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─a05a4f6d-c831-4fb1-9bca-7c69b794f8ce
# ╟─75003bf5-612e-4e32-aaf4-e53a77987b44
# ╟─bea73bf9-96c0-42fb-b795-033f6f2a0674
# ╟─bc689638-fd19-4c9f-935f-ddf6a6bfbbdd
# ╟─197fd00e-9068-46ea-af2a-25235e544a31
# ╠═f6d4f8c4-e441-45c4-8af5-148d95ea2900
# ╟─45740c4d-b789-45dc-a6bf-47194d7e8e12
# ╟─42b0f1e1-16c9-4238-828a-4cc485149963
# ╠═d09256dd-6c0d-4e28-9e54-3f7b3ca87ecb
# ╟─499cbc31-83ba-4583-ba1f-6363f43ec697
# ╟─2bac0883-5e62-4e1a-95ea-2955abd45275
# ╟─4afc3a94-c3e3-493e-b1b3-dd47e367ba54
# ╟─ab471845-15a5-40f8-8d7e-8e449afd1c48
# ╟─cd60f13d-4311-421c-a29f-71ab1e29b06e
# ╟─985baf9f-1507-442d-a949-7f3bd292fe31
# ╠═ae4f097b-4c18-4025-8514-99938a2932db
# ╠═88c11aa3-2c4c-4200-a0de-1721c1bc2df2
# ╟─27b51025-5fc0-4453-bca8-7eec7950fd82
# ╟─3b869e8a-24c4-4b00-9873-1b1430e635cc
# ╠═59e3c087-617d-457b-b43e-d0ebe87da176
# ╟─93ee20a1-6db9-4157-b69e-cfdc0501fdc6
# ╟─992ca8fb-1a20-4664-abd3-cb77d7a79683
# ╟─bf7f99f5-7096-441f-879e-dc128f3db7b3
# ╠═933cc42f-6be5-4b9b-a367-9aa3c6cf34d0
# ╟─8ad6eede-d717-4779-b8b2-fbca000635df
# ╠═f35ad4f4-2f4b-4a05-a9b5-48d93ef82b89
# ╟─b081e89d-3ded-4061-bf32-94657e65284e
# ╠═325b5554-5521-48da-9afd-65a5b5facac9
# ╟─2f1d872a-8471-4e85-b6c8-54f5ed90a964
# ╟─ce0ec15e-a419-4517-9292-fe822525fc77
# ╠═95d1dc5f-75d9-4297-ae5e-4b83dcbc9675
# ╟─c2ce1680-24a7-4a9e-908f-d77bb7f9a509
# ╠═aa58b3e3-bdda-433a-9c3d-3b151b04c0c3
# ╟─d31909f8-f5f1-4773-8a29-32f11452654a
# ╠═c1f7376d-6f42-497f-a5f1-151fcbe229a2
# ╠═2640cb64-bc0e-4bca-81bc-2d5603785a09
# ╠═ba53ad4c-e092-40fd-9d87-1d1fbb0e3997
# ╟─5e706d1f-93f3-4d50-b950-fddef2a1fb10
# ╠═7de5633e-8d59-4ad8-951b-64cb2a36c8e3
# ╠═2eb78823-0a9b-436d-b723-723d7e329376
# ╟─a42a2993-098f-4943-a87d-950c50fb2955
# ╠═db2d9ba2-1fc4-4a7f-8448-4bcb089096cd
# ╟─34feba2c-e700-423a-a012-a84240254fb6
# ╟─ad6637a0-b5f3-430c-bbdd-9799f7bb2e60
# ╠═622d0b24-ca8f-4bd4-97a7-88e3af4f10ee
# ╟─b98100f5-976f-4d6a-b372-8c9866e51852
# ╟─984397e2-ab08-4ef5-8f3d-b82f1e7b6f7a
# ╠═335d13dc-807d-491f-ab04-579e5608ae53
# ╠═96cba2ba-f64e-44a7-86cf-35420d9e6995
# ╟─e1e8e176-74da-437a-a29a-8d0445351914
# ╠═83b4291e-3842-4819-be65-28d0fcca50a8
# ╟─9a1e2ea6-4e31-49d5-9a2e-c468345d87d1
# ╠═af0c0a55-d994-452d-b5fa-cb79ebf595ef
# ╟─39a680a3-2e87-4b48-91c5-524da38aa391
# ╟─99cb052f-c512-4040-8c47-b070474202aa
# ╟─595983b4-3c4e-44af-ad90-b4405b216771
# ╠═72510848-3148-408a-895b-997a92b731e0
# ╟─c8700a21-e95b-4f0f-a525-e9b04a4bd246
# ╠═5b8d30eb-bd5c-4b09-80f0-ba7781e173cf
# ╟─a232a792-8692-45cc-9cbc-9a2c39793333
# ╠═62be4fb6-3b7e-4b80-b887-2b16710e5502
# ╟─3856cc2d-ea15-4077-9452-5298a8a4a401
# ╠═10b7acb8-1a3b-4dca-9f5e-a712a2f8a988
# ╠═5a86fd44-8e9b-4694-b017-96f1602f2cad
# ╟─7d8e68c8-430c-46dd-8be2-2a4017c45345
# ╟─fb9a3a2d-6b1a-4d64-a7ad-80d84f5b0070
# ╠═deef14fe-9822-4fa8-8378-5aa686f0b407
# ╟─d5308047-a4ee-41c8-9f43-49763e8691a1
# ╠═d8f73aeb-2b82-4afd-bb0e-3a45761c733a
# ╟─4d01b5f6-96bd-4d4d-bc5b-ef1078e2822f
# ╟─2ecd9ccb-45c4-4de4-9979-7044b2f2df33
# ╠═43887c78-378f-4bb8-b2a1-fbbde543f620
# ╟─43c25729-4bda-4c21-910b-f8a9a217eff2
# ╠═de239414-32a8-4691-aa36-d2e8546da46a
# ╟─2a1d3e22-d17c-452d-88a1-a2bf91434413
# ╠═ef2282bc-db28-4d54-a1cb-54e34396a855
# ╟─189c145c-17c5-4532-9cfb-0ec415e913ed
# ╟─b5918685-f6f7-49fd-8f4c-cb29f1b270ce
# ╟─9dbeeed8-d882-4e04-8037-0de5806e1a54
# ╠═7547798a-24c9-4c5f-9961-a09632c33fb0
# ╟─8ce96a51-938d-43d1-b7cc-46f4ef988c68
# ╠═04255053-ed5f-48d6-90fb-7f2721f6fcc7
# ╟─35af5a52-69f9-4b74-af65-ccd25ecb9818
# ╠═55531d1d-31e9-4e61-8890-979691212d9b
# ╟─87065854-efb2-44b7-a6fa-eaf14df5d44b
# ╟─e7472876-9209-4408-8f46-f6380fb9860b
# ╟─925a7014-51dc-4a55-8025-5084804a9f6c
# ╠═df4bd436-9b0e-484b-9e90-09023d201062
# ╟─2faf541c-1a2c-4274-b7bb-2f33ef765cc0
# ╠═ca444411-88c0-4c2c-9625-01172c4a0081
# ╟─49bcdff9-0e08-45e3-af4f-11c7de9e21dd
# ╟─9653dbb8-a168-4a07-8dba-241d9b744683
# ╠═1613d417-80ac-40bd-a6e5-2f0b4dca5c59
# ╟─b760d242-43de-4248-8550-20498aa03ed0
# ╠═f40a1541-ee37-487e-9e7b-5b943cf6b560
# ╟─523bcb12-f95d-4b90-bce6-0a1379cc1259
# ╠═691b9fb3-72c7-43bd-9608-b5032c116833
# ╠═880f9d8d-3095-45b5-b473-4aa968e6937a
# ╟─275f2017-5520-4072-8d9e-644a1b3cc6b6
# ╠═93533a8e-e507-4950-ac0a-23ded81445da
# ╟─1d455c06-389b-402a-8535-1a088a6a3228
# ╠═91b6e632-f1be-4b1f-8af9-a6bf29a06338
# ╠═76bc1d1e-3de7-461c-a39f-7893c73eef39
# ╟─bf534937-b3c5-4e01-bcca-51a27994a151
# ╠═8d59229c-1a70-40b2-9b33-09b4b6661170
# ╟─8b98a48c-d2c6-4ecf-b45d-88d068bb0fa2
# ╠═0fb6fa7a-f0c0-4926-92c8-6db3a590d963
# ╟─09a60a33-8b8d-4aed-abf5-96f457eb2bdf
# ╠═e08d911c-f1a4-40b5-8a60-2e0214c059f5
# ╟─8323c2ea-16bc-4913-a38a-beb5c7157b57
# ╟─b2227a29-b214-4683-81f5-507803ea9ed6
# ╠═c63ed6db-6d2a-4ee7-9b21-6d4eb642d87e
# ╟─f829c00b-f082-4ec4-b98c-3df1f31879bf
# ╠═727ecfae-2e87-4e05-92b7-4ceba56e97ad
# ╟─31359fe0-8d95-4740-b122-214de244406c
# ╠═1383b285-59f2-4652-8a4b-c83694978e38
# ╟─3c3b7c0f-ef92-4eeb-a8b6-f7ff516dedc4
# ╟─a6725314-8f98-4869-81e1-74ef03c2e79e
# ╠═174b9a92-2cf5-4630-a04e-0b76409c14a7
# ╟─51f56327-7309-4aa2-b979-3458f2f26667
# ╟─f2becd33-0b66-4b13-97e3-6677afc6ca9f
# ╠═1d65816d-d818-434d-b10e-562ce21caa04
# ╠═91cefb80-4c5b-4a1a-837b-47e9cebfb913
# ╠═97400000-e067-4c66-8f78-ab549ef1544e
# ╟─e80b6400-2c9e-4198-a8a4-a53f5149481e
# ╟─fc268355-011e-44d5-8704-dbab8e09b4f1
# ╟─25164534-5e28-44f4-a02f-27b6c05e4d02
# ╟─1ffaccf9-a0ec-451c-bea4-3d467d48781c
# ╟─14a71476-a7ca-4324-97c5-2979af8a507d
# ╟─47c32a4a-5596-4970-b639-63c76c72c513
# ╠═9a75c053-59ba-4c53-8f5a-e1ee9eb5c15c
# ╠═f3de7b01-d9e5-4b5c-adc5-e671db8bca5d
# ╟─158df0a8-625f-4389-86f1-0ea38de21abb
# ╟─0cec3967-8a9e-4da5-a55c-0cb44ab816d7
# ╟─1dcadbe8-6897-48bb-be86-92ecfd0d2343
# ╠═f303e667-6485-4949-9cf1-facf39e3f302
# ╠═a1c60d89-5d61-4a26-b61c-748aec38e674
# ╟─b5b23e79-35ce-4857-9727-ed822e4fd85d
# ╠═8346cbaa-16bb-4f7a-b2f2-e08965e5be66
# ╠═b4ecc31b-4105-4a38-aff1-7de2c05d16f0
# ╠═76dc6ac8-03fe-4c6e-a543-f9324a87efad
# ╟─0860f65e-8e80-4394-8657-9fba0caf3cb7
# ╟─17b6bf6e-31d0-4981-a217-e58f442fc85c
# ╠═6df9f266-f9d9-4506-b8ad-0340f15a03ba
# ╟─0afa73e6-f371-4b04-946d-b124a8db5f7c
# ╟─fed7482b-707f-46f0-b582-dfcbeb05bcc5
# ╟─84ccf4c1-e3c5-4d25-806e-1bc580dc349d
# ╟─c2cda2eb-6110-4b1f-93d8-53c527b0a48c
# ╟─135dac9b-0bd9-4e1d-af98-8dffdf3118fc
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
