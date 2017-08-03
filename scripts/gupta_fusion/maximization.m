function [t_k, sigma_k, theta, sigma_m] = maximization(features_mat, a_star, theta, annotations_mat, ...
                t_k, annotatorid_array, fileid_array)
% Anil Ramakrishna | akramakr@usc.edu
% This function performs the Maximization-step. For each annotator, it computes
% the corresponding t_k, sigma_k as well as theta and sigma_m.
    
    uniq_annotators = unique(annotatorid_array); 
    uniq_files = unique(fileid_array);
    k = numel(uniq_annotators);     % number of annotators
    m = numel(uniq_files);   % number of files
    p = size(features_mat{1}, 2); % number of features per data point
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    W=8; 
    sigma_k = zeros(k, 1);
    sigma_m = zeros(m, 1);
    
    find_sigma_k = true;    % Skipping this for now since this is a heavy operation; turn back on later

    %Estimate sigma_m
    for iter1=1:m
        cur_a_star = a_star{iter1};
        t = size(cur_a_star, 1);
        cur_features_mat = features_mat{iter1};
        sigma_m(iter1) = sqrt(sum(sum((cur_a_star - cur_features_mat*theta).^2))/(t*d-1));
    end
    
    for iter1=1:k
        data_points_with_cur_ann_id = find(annotatorid_array == iter1);
        
        for iter2=1:d
            t_k_X = [];
            t_k_y = [];

            num_noise_terms = 0;
            %Estimate t_k and sigma_k
            for iter3=1:numel(data_points_with_cur_ann_id)
                data_point_id = data_points_with_cur_ann_id(iter3);
                cur_file_id = fileid_array(data_point_id);
                cur_a_star = a_star{cur_file_id};
                cur_annotation = annotations_mat{data_point_id};
                t = size(cur_annotation,1);
                
                t_k_y = [t_k_y; cur_annotation(:,iter2)];
                tmp_vec=cur_a_star(:,iter2);
                matrix_M = extract_timeshifted_matrix_from_vec(tmp_vec, t, W);
                t_k_X = [t_k_X; matrix_M];
                
                if find_sigma_k
                    cur_T_k = extract_T_k_from_vec(t_k(:, iter2, iter1), t);
                    sigma_k(iter1) = sigma_k(iter1) + sum(sum((cur_annotation(:, iter2) - cur_T_k*cur_a_star(:,iter2))).^2);
                    num_noise_terms = num_noise_terms + t;
                end
            end
            t_k(:, iter2, iter1) = lsqnonneg(t_k_X,t_k_y);
        end
        if find_sigma_k
            sigma_k(iter1) = sqrt(sigma_k(iter1)/(num_noise_terms - 1));
        end
    end

    XbarX = zeros(p, p);
    Xbary = zeros(p, d);

    %Estimate theta
    for iter1=1:m
        cur_a_star = a_star{iter1};
        cur_features_mat = features_mat{iter1};
        
        XbarX = XbarX + (cur_features_mat' * cur_features_mat);
        Xbary = Xbary + (cur_features_mat' * cur_a_star);
    end
    if abs(rcond(XbarX)) < 1e-15
        XbarX = XbarX + eye(p);
    end
    
    theta = inv(XbarX) * Xbary;
end