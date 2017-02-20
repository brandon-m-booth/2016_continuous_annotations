module Triplets

using PyCall
@pyimport cy_tste

	function generate_triplets(data)

		triplets = zeros(Int64,3,10000000)
		counter = 0

		for i = 1:length(data)
		    for j = 1:length(data)
		        for k = 1:length(data)
		            if i != j && i != k
		                distance_ij = abs(data[i] - data[j]);
		                distance_ik = abs(data[i] - data[k]);
		                if distance_ij < distance_ik
												counter = counter + 1;
		                    triplets[:,counter] = [i; j; k];
		                end
		            end
		        end
		    end
		end
	        return triplets[:,1:counter]
	end

	function scaling(data, X)

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
		return (X_copy-X[260])*(max_value-min_value)/(X[100]-X[260]) + min_value

	end

	function calculate_embedding(trplts, fraction)
		total = size(trplts)[2]
		amount = convert(Int64, floor(fraction*total))

		subset_triplets = trplts[:,rand(1:size(trplts)[2], amount)]
		@time X, triplet_violations = cy_tste.tste(PyReverseDims(subset_triplets), 1, 0, 2)
		X = X[2:end,1] # Why is the embedding 268x1 instead of 267x1? Need to check

		return X, triplet_violations
	end

end # module
