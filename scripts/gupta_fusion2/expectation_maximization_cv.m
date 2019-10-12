function [] = expectation_maximization_cv(varargin)
% Anil Ramakrishna | akramakr@usc.edu
% This is the main program that runs the hard EM algorithm to estimate the
% latent ground truth and annotator parameters for the Independent case

    dataset = 1;
    if dataset == 1
        data_dir = '../../Data/synthetic/matfiles/Joint/';
        suffix = '_synth';
    elseif dataset == 2
        data_dir = '../../Data/movieemotions/matfiles/';
        suffix = '';
    elseif dataset == 3
        data_dir = '../../Data/synthetic_color_change/matfiles/';
        suffix = '';
    end
    threshold = 1e-4;
    
    %Workaround for a known bug in Matlab
    feature scopedAccelEnablement off
    
    load([data_dir 'data_matrix' suffix '.mat'], 'annotations_mat');
    t = size(annotations_mat{1}, 1);    %number of time steps
    
    W_list = [(5:10)'; (15:5:25)'; (30:10:90)'; (100:100:t)'];
    W_corr_list = zeros(numel(W_list),1);
    num_folds = 5;
    
    for iter_w = 1:numel(W_list)
        W = W_list(iter_w);
        load([data_dir 'data_matrix' suffix '.mat']);

        m = numel(unique(fileid_array));   % number of files
        %out_file_name = ['estimatedParameters' suffix '_windowsize' num2str(W) '.mat'];
        partitions = create_data_splits(num_folds, a_star, features_mat, annotations_mat, annotatorid_array, fileid_array);
        cv_results = zeros(num_folds, 1);

        fprintf('Currently running %d fold CV experiment for filter size %d\n', num_folds, W);
        for iter_fold = 1:num_folds
            %Train data
            features_mat = partitions.folds(iter_fold).train.features_mat;
            annotations_mat = partitions.folds(iter_fold).train.annotations_mat;
            annotatorid_array = partitions.folds(iter_fold).train.annotatorid_array;
            fileid_array = partitions.folds(iter_fold).train.fileid_array;
            a_star_gt = partitions.folds(iter_fold).train.a_star_gt;
            
            uniq_files = unique(fileid_array);
            uniq_annotators = unique(annotatorid_array);
            k = numel(uniq_annotators);     % number of annotators
            d = size(annotations_mat{1}, 2); % number of annotations per data point
            p = size(features_mat{1}, 2); % number of features per data point
            
            a_star = cell(m,1);
            %Initialize a_star, t_k, sigma_k, sigma_m and theta with jump start
            for iter_file = 1:numel(uniq_files)
                cur_file_id = uniq_files(iter_file);
                cur_file_inds = (fileid_array==cur_file_id);
                tmp_cell_array = annotations_mat(cur_file_inds);
                a_star{cur_file_id} = mean(cat(3,tmp_cell_array{:}), 3);
            end
            F_k = rand(W,d,k);
            theta = rand(p,d);
            [F_k, ~, theta, ~] = maximization(features_mat, a_star, theta, annotations_mat, ...
                F_k, annotatorid_array, fileid_array);
        
            counter = 0; oldPData = 100000;
            %Main loop that runs EM until convergence
            while(true)
                %E-step: estimate a_star
                a_star = expectation(m, features_mat, a_star, annotations_mat, annotatorid_array, fileid_array, ...
                    F_k, theta);

                %M-step: update annotator parameters
                [F_k, tau_k, theta, sigma] = maximization(features_mat, a_star, theta, annotations_mat, ...
                    F_k, annotatorid_array, fileid_array);

                %compute current likelihood function value
                [pData] = compute_p_data(features_mat, annotations_mat, annotatorid_array, ...
                    fileid_array, a_star, theta, sigma, F_k, tau_k);

                if counter >= 1 && abs((pData - oldPData)/oldPData) < threshold
                    break;
                else
                    counter = counter + 1;
                    fprintf('Log likelihood at counter value %d is %f\n', counter, pData);
                    oldPData = pData;
                    old_a_star = a_star;
                end
            end
            
            %Test data
            annotations_mat = partitions.folds(iter_fold).test.annotations_mat;
            annotatorid_array = partitions.folds(iter_fold).test.annotatorid_array;
            fileid_array = partitions.folds(iter_fold).test.fileid_array;
            test_a_star_gt = cell2mat(a_star_gt(partitions.folds(iter_fold).test.test_files));
            
            test_a_star = cell2mat(expectation(m, features_mat, a_star, annotations_mat, annotatorid_array, fileid_array, ...
                    F_k, theta));
                
            cv_results(iter_fold) = corr(test_a_star_gt(:), test_a_star(:));
        end
        W_corr_list(iter_w) = mean(cv_results);
    end
    [~,best_w_ind] = max(W_corr_list);
    save('../../Data/synthetic/results/Independent/5fold_cv_scores.mat', 'W_list', 'W_corr_list');
    fprintf('Best window size based on 5 fold CV was %d with %f correlation\n', W_list(best_w_ind), W_corr_list(best_w_ind));
end
