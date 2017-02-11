include("Triplets.jl")

using DataFrames
using Plots
using Triplets
using PyCall
using NPZ

path = "/Users/karel/Documents/Research/BEAM/2016_continuous_annotations/scripts/ordinal_embedding/tste/triplet_ground_truth/gt_objective.csv"
data = readtable(path)
data = data[:,1] # retrieve the column with data
data = data[1:30:end] # slice the data to have a 1 sample/second

# N = 50
# data = data[N+1:2N]
plot(data)

@time trplts = Triplets.generate_triplets(data)

npzwrite("triplets.npy", trplts)
