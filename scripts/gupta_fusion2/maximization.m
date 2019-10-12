function [F_k, tau_k, theta, sigma] = maximization(features_mat, a_star, theta_old, annotations_mat, ...
                F_k_old, annotatorid_array, fileid_array)
% Anil Ramakrishna | akramakr@usc.edu
% This function performs the Maximization-step. For each annotator, it computes
% the corresponding F_k, tau_k as well as theta and sigma.
    
    uniq_annotators = unique(annotatorid_array); 
    uniq_files = unique(fileid_array);
    k = numel(uniq_annotators);     % number of annotators
    p = size(features_mat{1}, 2); % number of features per data point
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    W = size(F_k_old, 1); 
    tau_k = zeros(k, 1);
    sigma = 0;
    noise_limit = 0.01; noise_term_correction = false;
    F_k = zeros(size(F_k_old));
    
    %Estimate sigma
    sigma_norm = 0;
    for iter_file=1:numel(uniq_files)
        cur_file_id = uniq_files(iter_file);
        cur_a_star = a_star{cur_file_id};
        cur_features_mat = features_mat{cur_file_id};
        sigma = sigma + norm(cur_a_star - cur_features_mat*theta_old, 'fro');
        sigma_norm = sigma_norm + numel(cur_a_star);
    end
    sigma = sigma / sigma_norm;
    
    %Add a lower limit to noise as sometimes this goes to 0 leading to
    %unpredictable results
    if noise_term_correction
        if sigma < noise_limit
            sigma = noise_limit;
        end
    end
    
    for iter_ann=1:k
        cur_ann_id = uniq_annotators(iter_ann);
        data_points_with_cur_ann_id = find(annotatorid_array == cur_ann_id);
        
        for iter_target_d=1:d
            F_k_XtX = zeros(W,W);
            F_k_Xty = zeros(W,1);
            
            tau_k_norm = 0;
            %Estimate F_k and tau_k
            for iter_data=1:numel(data_points_with_cur_ann_id)
                data_point_id = data_points_with_cur_ann_id(iter_data);
                cur_file_id = fileid_array(data_point_id);
                cur_a_star = a_star{cur_file_id};
                t = size(cur_a_star, 1);
                cur_annotation = annotations_mat{data_point_id};
                
                cur_F_k_X = extract_timeshifted_matrix_from_vec(cur_a_star(:,iter_target_d), t, W);
                F_k_XtX = F_k_XtX + cur_F_k_X'*cur_F_k_X;
                F_k_Xty = F_k_Xty + cur_F_k_X'*cur_annotation(:,iter_target_d);
                
                %There must be a more efficient way to do this
                cur_F_k = extract_T_k_from_vec(F_k_old(:, iter_target_d, cur_ann_id), t);
                tau_k(cur_ann_id) = tau_k(cur_ann_id) + norm(cur_annotation(:, iter_target_d) - cur_F_k*cur_a_star(:,iter_target_d));
                tau_k_norm = tau_k_norm + t;
            end
            if abs(rcond(F_k_XtX)) < 1e-15
                F_k_XtX = F_k_XtX + eye(W);
            end
            F_k(:, iter_target_d, cur_ann_id) = inv(F_k_XtX) * F_k_Xty;
        end
        
        tau_k(cur_ann_id) = tau_k(cur_ann_id)/tau_k_norm;
        
        if noise_term_correction
            if tau_k(cur_ann_id) < noise_limit
                tau_k(cur_ann_id) = noise_limit;
            end
        end
    end

    XbarX = zeros(p, p);
    Xbary = zeros(p, d);

    %Estimate theta
    for iter_file=1:numel(uniq_files)
        cur_file_id = uniq_files(iter_file);
        cur_a_star = a_star{cur_file_id};
        cur_features_mat = features_mat{cur_file_id};
        
        XbarX = XbarX + (cur_features_mat' * cur_features_mat);
        Xbary = Xbary + (cur_features_mat' * cur_a_star);
    end
    if abs(rcond(XbarX)) < 1e-15
        XbarX = XbarX + eye(p);
    end
    theta = inv(XbarX) * Xbary;
end