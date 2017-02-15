include("Triplets.jl")

using DataFrames
using Triplets
using NPZ

# In order to use cy_tste, we need to give the right Python installation
ENV["Python"] = "~/anaconda/bin/python"
Pkg.build("PyCall")
using PyCall
@pyimport cy_tste
@pyimport numpy as np

path = "/Users/karel/Documents/Research/BEAM/2016_continuous_annotations/scripts/ordinal_embedding/tste/triplet_ground_truth/gt_objective.csv"
data = readtable(path)
data = data[:,1] # retrieve the column with data
data = data[1:30:end] # slice the data to have 1 sample/second

# N = 50
# data = data[N+1:2N]
# plot(data)

@time trplts = Triplets.generate_triplets(data)

#npzwrite("triplets.npy", trplts)

fraction = 0.01
total = size(trplts)[2]
amount = convert(Int64, floor(fraction*total))

subset_triplets = trplts[:,rand(1:size(trplts)[2], amount)]
@time X = cy_tste.tste(PyReverseDims(subset_triplets), 1, 0, 2)

plot(X)
