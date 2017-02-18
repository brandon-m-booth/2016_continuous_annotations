include("Triplets.jl")

using DataFrames
using Triplets
using NPZ
using PyCall
@pyimport cy_tste

# In order to use cy_tste, we need to give the right Python installation
# ENV["Python"] = "~/anaconda/bin/python"
# Pkg.build("PyCall")

path = "/Users/karel/Documents/Research/BEAM/2016_continuous_annotations/scripts/ordinal_embedding/tste/triplet_ground_truth/gt_objective.csv"
data = readtable(path)
data = data[:,1] # retrieve the column with data
data = data[1:30:end] # slice the data to have 1 sample/second

# N = 50
# data = data[N+1:2N]
# plot(data)

@time trplts = Triplets.generate_triplets(data)

#npzwrite("triplets.npy", trplts)

fraction = 0.1
total = size(trplts)[2]
amount = convert(Int64, floor(fraction*total))

subset_triplets = trplts[:,rand(1:size(trplts)[2], amount)]
@time X = cy_tste.tste(PyReverseDims(subset_triplets), 1, 0, 2)


# Plotting
min_value = minimum(data)
max_value = maximum(data)

if X[85] > X[100] # flip X
    X = -X
end

X_scaled = (X-minimum(X))*(max_value-min_value)/(maximum(X)-minimum(X)) + min_value

# We need to match the dimensions. Why is the dimension of the embedding 1 value
# bigger than it should be?
X_scaled = X_scaled[2:end,1]
to_plot = [X_scaled data]
plot(to_plot)
