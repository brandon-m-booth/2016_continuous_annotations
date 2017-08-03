function ordinateIntervals(output_file_path, approximate_signal_csv, truth_signal_csv, intervals_csv, comparison_retain_percentage, correctness_rate)
% Generates an embedding using t-STE and simulated triplet comparisons.  The
% triplets are created from the approximate signal over the constant intervals
% by peaking at the true signal.  The correctness_rate affects the probability
% of not adversarially flipping each triplet comparison and the
% comparison_retain_percentage is the fraction of all possible triplets
% that are used to construct the embedding.
    switch nargin
        case 1
            correctness_rate = 1.0;
        case 0
            comparison_retain_percentage = 1.0;
            correctness_rate = 1.0;
    end

    addpath(strcat(mfilename('fullpath'), 'tste'));

    %% Load data
    signal = csvread(approximate_signal_csv, 1, 1);
    obj_truth = csvread(truth_signal_csv, 1, 1);
    intervals = csvread(intervals_csv);

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
                    %if i == 20
                    %   triplets(triplet_idx,:) = [i,j,k];
                    %   triplet_idx = triplet_idx + 1;
                    %end
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

    %% Flip the polarity of the triplet comparison for some of the triplets
    num_flips = round((1.0-correctness_rate)*size(triplets,1));
    for flip_idx=1:num_flips
        triplets(flip_idx,:) = [triplets(flip_idx,1), triplets(flip_idx,3), triplets(flip_idx,2)];
    end

    %% t-STE embedding
    d = 1;
    lambda = 0.0;
    alpha = 1.0;
    embedding = tste(triplets, d, lambda, alpha);

    %% Rescale each embedding uniformly to [0,1] interval and flip if necessary
    mean_emb = mean(embedding);
    max_emb = max(abs(embedding-mean_emb));
    embedding = (embedding-mean_emb)/max_emb + mean_emb;
    if corr(embedding,obj_mean-mean(obj_mean)) >= 0
        embedding = 0.5*embedding + 0.5;
    else
        embedding = -0.5*embedding + 0.5;
    end

    %%  Plot the results
%         close all
%         figure
%         M=1;
%         subplot_rows = 1;
%         subplot_cols = ceil(M/subplot_rows);
%         for m=1:M
%             subplot(subplot_rows,subplot_cols,m);
%             plot(signal, 'b-'); hold on;
%             for i=1:size(intervals,1)
%                 plot(intervals(i,:), [obj_mean(i),obj_mean(i)], 'r-o'); hold on;
%                 plot(intervals(i,:), [embedding(i,:),embedding(i,:)], 'g-o'); hold on;
%             end
%             xlabel('Time(s)');
%             ylabel('Green Saturation');
%             legend('Average Signal', 'Intervals', 'Triplets');
%         end

    csvwrite(output_file_path, embedding);
