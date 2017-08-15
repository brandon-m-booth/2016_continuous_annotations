function [a_star, sigma_m, theta, t_k, sigma_k, counter, features_mat] = expectation_maximization(varargin)
% Anil Ramakrishna | akramakr@usc.edu
% This is the main program that runs the hard EM algorithm to estimate the
% latent ground truth and annotator parameters

    max_iters = 50;
   
    load('data_matrix.mat');

    data_indices = find(ones(size(fileid_array)) == 1);
    out_file_name = 'estimatedParameters.mat';
    
    %Workaround for a known bug in Matlab
    feature scopedAccelEnablement off
    
    %Use only training data
    annotations_mat = annotations_mat(data_indices);
    annotatorid_array = annotatorid_array(data_indices);
    fileid_array = fileid_array(data_indices);
    
    k = numel(uniq_annotators);     % number of annotators
    m = numel(uniq_files);   % number of files
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    p = size(features_mat{1}, 2); % number of features per data point
    W=8; % causal DTI window
    oldPData = 100000;
    eps = 1e-4; 

    %Initialize a_star, t_k, sigma_k, sigma_m and theta with jump start
    for iter1=1:m
        cur_file_inds=(fileid_array==iter1);
        tmp_cell_array = annotations_mat(cur_file_inds);
        a_star{iter1} = mean(cat(3,tmp_cell_array{:}), 3);
    end
    t_k = rand(W,d,k);
    theta = rand(p, d);
    [t_k, sigma_k, theta, sigma_m] = maximization(features_mat, a_star, theta, annotations_mat, ...
            t_k, annotatorid_array, fileid_array);

    if false        
        %Use randomly initialized a_star instead of annotator means
        for iter1=1:m
            t = size(annotations_mat{iter1},1);
            a_star{iter1} = rand(t,d);
        end
        t_k = rand(W,d,k);
        theta = rand(p, d);
        [t_k, sigma_k, theta, sigma_m] = maximization(features_mat, a_star, theta, annotations_mat, ...
                t_k, annotatorid_array, fileid_array);
    end
    
    counter = 0;
    %Main loop that runs EM until convergence
    while(true)
        %Adding noise to speed up EM; see [Osaba et al. 2013, corollary 4]
        
        %Adding noise to all parameters to help avoid local optima
        if false
            noise_sd = 1/(counter+1)^2*0.01;
            a_star = a_star + normrnd(0, noise_sd, size(a_star));
            t_k = t_k + normrnd(0, noise_sd, size(t_k));
            theta = theta + normrnd(0, noise_sd, size(theta));
        end

        %E-step: estimate a_star
        a_star = expectation(features_mat, a_star, annotations_mat, annotatorid_array, fileid_array, ...
            t_k, theta);

        %M-step: update annotator parameters
        [t_k, sigma_k, theta, sigma_m] = maximization(features_mat, a_star, theta, annotations_mat, ...
            t_k, annotatorid_array, fileid_array);
        
        %compute current likelihood function value
        [pData] = compute_p_data(features_mat, annotations_mat, annotatorid_array, ...
            fileid_array, a_star, theta, sigma_m, t_k, sigma_k);
        
        if counter == max_iters %|| abs(oldPData - pData) < threshold
            break;
        else
            counter = counter + 1;
            fprintf('Log likelihood at counter value %d is %f\n', counter, pData);
            oldPData = pData;
            old_a_star = a_star;
        end
    end

    save([out_file_name], 'a_star', 'sigma_m', 'theta', 't_k', 'sigma_k', 'counter', 'features_mat');
end
