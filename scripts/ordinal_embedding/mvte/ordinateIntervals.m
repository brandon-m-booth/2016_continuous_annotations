%% Load data
signal = csvread('/USC/2016_Continuous_Annotations/gt_data/time_shifted/gt_mariooryad_evaldep.csv');
obj_truth = csvread('/USC/2016_Continuous_Annotations/gt_data/time_shifted/gt_objective.csv');
intervals = csvread('/USC/2016_Continuous_Annotations/gt_data/time_shifted/intervals.csv');
output_file = '/USC/2016_Continuous_Annotations/gt_data/time_shifted/interval_values.csv'
comparison_retain_percentage = 1.0;

%L = 5000;
%W = 100;
%intervals = zeros(L/W,2);
%intervals(:,1) = linspace(0,L-W,L/W)';
%intervals(:,2) = linspace(W,L,L/W)'-1;
%obj_truth = linspace(0,1,L);

%% For each interval, compute the average obj truth value
obj_mean = zeros(size(intervals,1),1);
for i=1:size(intervals,1)
    interval = intervals(i,:);
    obj_mean(i) = mean(obj_truth(interval(1)+1:interval(2)+1));
end

%% Generate triplets such that for each (i,j,k), the obj_truth at index i is closer to k than j
n = size(intervals,1);
num_triplets = n*(n-1)*(n-2)/2;
num_triplets = 2*num_triplets; % Worst case if all comparisons are equal
triplets = zeros(num_triplets,3);
triplet_idx = 1;
diff_eps = 0.01;
for i=1:size(intervals,1)
    for j=1:size(intervals,1)
        if i == j
            continue;
        end
        for k=j+1:size(intervals,1)
            if i == k
                continue;
            end
            diff_ij = norm(obj_mean(i)-obj_mean(j));
            diff_ik = norm(obj_mean(i)-obj_mean(k));
            if abs(diff_ik - diff_ij) < diff_eps
                % If similar, add one triplet for both cases
                %triplets(triplet_idx,:) = [i,k,j];
                %triplet_idx = triplet_idx + 1;
                %triplets(triplet_idx,:) = [i,j,k];
                %triplet_idx = triplet_idx + 1;
            elseif diff_ik < diff_ij
                triplets(triplet_idx,:) = [i,k,j];
                triplet_idx = triplet_idx + 1;
            else
                triplets(triplet_idx,:) = [i,j,k];
                triplet_idx = triplet_idx + 1;
            end
        end
    end
end

%% Remove rows with all zeros
[i,j] = find(triplets);
triplets = triplets(unique(i),:);

%% Uniformly retain some percentage of the triplets
triplets = triplets(randperm(size(triplets,1)),:);
num_retain_triplets = round(size(triplets,1)*comparison_retain_percentage);
triplets = triplets(1:num_retain_triplets,:);

%% MVTE embedding
d = 1;
M = 1;
embedding = mvte(triplets, M, d);

%% Rescale each embedding uniformly to [0,1] interval and flip if necessary
for m=1:M
    mean_emb = mean(embedding(:,:,m));
    max_emb = max(abs(embedding(:,:,m)-mean_emb));
    embedding(:,:,m) = (embedding(:,:,m)-mean_emb)/max_emb + mean_emb;
    if corr(embedding(:,:,m),obj_mean-mean(obj_mean)) >= 0
        embedding(:,:,m) = 0.5*embedding(:,:,m) + 0.5;
    else
        embedding(:,:,m) = -0.5*embedding(:,:,m) + 0.5;
    end
end

%%  Plot the results
close all
figure
subplot_rows = 1;
subplot_cols = ceil(M/subplot_rows);
for m=1:M
    subplot(subplot_rows,subplot_cols,m);
    plot(signal, 'b-'); hold on;
    for i=1:size(intervals,1)
        plot(intervals(i,:), [obj_mean(i),obj_mean(i)], 'r-o'); hold on;
        plot(intervals(i,:), [embedding(i,:,m),embedding(i,:,m)], 'g-o'); hold on;
    end
    xlabel('Time(s)');
    ylabel('Green Saturation');
    legend('Average Signal', 'Intervals', 'Triplets');
end

csvwrite(output_file, embedding);
