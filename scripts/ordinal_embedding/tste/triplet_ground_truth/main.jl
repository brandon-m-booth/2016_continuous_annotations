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
@time X, triplet_violations = cy_tste.tste(PyReverseDims(subset_triplets), 1, 0, 2)
X = X[2:end,1] # Why is the embedding 268x1 instead of 267x1? Need to check

# Re-scaling: Using two points that usually are no
# min_value = minimum(data)
min_value = data[260]
# max_value = maximum(data)
max_value = data[100] # Hard-coded value for rescaling

if X[90] > X[100] # flip X if needed
    X = -X
end

# Clip: When there are violation triplets that go beyond -100 or +100
X_copy = copy(X)
if maximum(X) > 85 || minimum(X) < -70
  X_copy = copy(X)
  X[X .< -70] = 0
  X[X .> 85] = 0
end

# To scale X into [a,b] use: x_scaled = (x-min(x))*(b-a)/(max(x)-min(x)) + a
X_scaled = (X_copy-X[260])*(max_value-min_value)/(X[100]-X[260]) + min_value

# Plots
to_plot = [data X_scaled]
labels = Array(String, 1, 2)
labels[1] = "Ground truth"
labels[2] = "Annotations"

plot(to_plot,
     title = "Continuous time annotations",
     xlabel = "Time",
     ylabel = "Green level",
     label = labels)
# gui()
