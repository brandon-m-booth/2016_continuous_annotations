clear; close all; clc;

N = 50;

data = csvread('./gt_objective.csv');
data = data(1:30:end);
data = data((N+1):2*N);
% plot(data);

triplets = [];

for i = 1:length(data)
    for j = 1:length(data)
        for k = 1:length(data)
%             if pdist(data([i j],:)) < pdist(data([i k],:)) && i ~= j && i ~= k 
            if abs(data(i) - data(j)) < abs(data(i) - data(k)) && i ~= j && i ~= k 
                triplets = [triplets; [i j k]];
            end  
        end
    end
end

% number_of_triplets = length(triplets);
% values = randi([1 number_of_triplets], 0.2*number_of_triplets, 1);
X = tste(triplets, 1,0,2);

subplot(2,1,1); plot(data,'or'); title('Ground truth');
subplot(2,1,2); plot(X,'o'); title('Ground truth from triplets');