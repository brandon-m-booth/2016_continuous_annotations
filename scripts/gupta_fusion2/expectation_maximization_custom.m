function a_star = expectation_maximization_custom(features_mat, annotations_mat, annotatorid_array, fileid_array, uniq_files, a_star_gt)
% Anil Ramakrishna | akramakr@usc.edu
% Edited: Brandon Booth | brandon.m.booth@gmail.com
% This is the main program that runs the hard EM algorithm to estimate the
% latent ground truth and annotator parameters for the Independent case
    W = 32;
    suffix = '';
    threshold = 1e-8;
    
    fprintf('Running EM for the continuous independent model with data %d\n', dataset);

    out_file_name = ['estimatedParameters' suffix '.mat'];
    
    %Workaround for a known bug in Matlab
    feature scopedAccelEnablement off
    
    t = size(annotations_mat{1}, 1);    %number of time steps
    m = numel(uniq_files);   % number of files
    
    %Run EM algorithm over array of data splits
    train_scores = [];
    results = [];
        
    %Train data
    %features_mat = data.train.features_mat;
    %annotations_mat = data.train.annotations_mat;
    %annotatorid_array = data.train.annotatorid_array;
    %fileid_array = data.train.fileid_array;
    %a_star_gt = data.train.a_star_gt;

    uniq_files = unique(fileid_array);
    uniq_annotators = unique(annotatorid_array);
    k = numel(uniq_annotators);     % number of annotators
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    p = size(features_mat{1}, 2); % number of features per data point

    %Initialize all parameters randomly
    a_star = cell(m,1);
    for i = 1:m
        a_star{i} = rand(size(a_star_gt{i}));
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
        %if counter == 50
            break;
        else
            counter = counter + 1;
            fprintf('Log likelihood at counter value %d is %f\n', counter, pData);
            oldPData = pData;
            old_a_star = a_star;
        end
    end

    %Test data (actually still the training set data)
    %annotations_mat = data.test.annotations_mat;
    %annotatorid_array = data.test.annotatorid_array;
    %fileid_array = data.test.fileid_array;
    %test_a_star_gt = cell2mat(a_star_gt(data.test.test_files));

    test_a_star = expectation(m, features_mat, a_star, annotations_mat, annotatorid_array, fileid_array, ...
            F_k, theta);
    %test_a_star = cell2mat(test_a_star(data.test.test_files));

    res = struct;
    res.a_star = a_star;
    res.theta = theta;
    res.F_k = F_k;
    res.tau_k = tau_k;
    res.sigma = sigma;
    res.counter = counter;
    %res.test_a_star_gt = test_a_star_gt;
    res.test_a_star = test_a_star;
    %results = [results; res];

    %test_set_corr = corr(test_a_star_gt(:), test_a_star(:));
    %test_set_ccc = ccc(test_a_star_gt(:), test_a_star(:));
    %test_scores = [test_scores; [test_set_corr, test_set_ccc]];
    
    %fprintf('%d fold average test set combined performance for estimated model parameters was %f, %f\n', ...
    %    numel(data_splits), mean(test_scores, 1));
    %save([results_dir out_file_name], 'data_splits', 'results');
end
