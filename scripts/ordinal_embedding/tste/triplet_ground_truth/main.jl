include("Triplets.jl")

using Triplets
using DataFrames
using Triplets
using NPZ
using Plots
plotly() #Plots backend (opens plot in browser using Plotly)

# Load data and slice to have 1 sample/second
path = "/Users/karel/Documents/Research/BEAM/2016_continuous_annotations/scripts/ordinal_embedding/tste/triplet_ground_truth/gt_objective.csv"
data = readtable(path)
data = data[:,1] # retrieve the column with data
data = data[1:30:end] # slice the data to have 1 sample/second

# Generate triplets
@time triplets = Triplets.generate_triplets(data)

# Calculate embedding from triplets
fraction = 0.04
X, triplet_violations = Triplets.calculate_embedding(triplets, fraction)

# Re-scaling: Using two points that usually are no
# min_value = minimum(data)
X_scaled = Triplets.scaling(data,X)

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
