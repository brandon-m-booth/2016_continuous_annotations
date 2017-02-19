include("Triplets.jl")

using DataFrames
using Triplets
using NPZ
using PyCall
using Plots
plotly() #Plots backend (opens plot in browser using Plotly)
@pyimport cy_tste

# Load data and slice to have 1 sample/second
path = "/Users/karel/Documents/Research/BEAM/2016_continuous_annotations/scripts/ordinal_embedding/tste/triplet_ground_truth/gt_objective.csv"
data = readtable(path)
data = data[:,1] # retrieve the column with data
data = data[1:30:end] # slice the data to have 1 sample/second

# Generate triplets
@time trplts = Triplets.generate_triplets(data)

# Calculate embedding from triplets
fraction = 0.04
total = size(trplts)[2]
amount = convert(Int64, floor(fraction*total))

subset_triplets = trplts[:,rand(1:size(trplts)[2], amount)]
@time X = cy_tste.tste(PyReverseDims(subset_triplets), 1, 0, 2)
X = X[2:end,1] # Why is the embedding 268x1 instead of 267x1? Need to check

# Re-scaling
min_value = minimum(data)
max_value = maximum(data)

if X[90] > X[100] # flip X if needed
    X = -X
end

X_scaled = (X-minimum(X))*(max_value-min_value)/(maximum(X)-minimum(X)) + min_value

# Plots
to_plot = [data X_scaled]
labels = Array(String, 1, 2)
labels[1] = "Annotations"
labels[2] = "Ground truth"

plot(to_plot,
     title = "Continuous time annotations",
     xlabel = "Time",
     ylabel = "Green level",
     label = labels)
# gui()
