module Triplets

	function generate_triplets(data)

		triplets = zeros(Int64,10000000,3)
		counter = 0

		for i = 1:length(data)
		    for j = 1:length(data)
		        for k = 1:length(data)
		            if i != j && i != k
		                distance_ij = abs(data[i] - data[j]);
		                distance_ik = abs(data[i] - data[k]);
		                if distance_ij < distance_ik
												counter = counter + 1;
		                    triplets[counter,:] = [i j k];
		                end
		            end
		        end
		    end
		end
	        return triplets[1:counter,:]
	end

end # module
