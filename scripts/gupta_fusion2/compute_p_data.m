function [pData] = compute_p_data(features_mat, annotations_mat, annotatorid_array, ...
            fileid_array, a_star, theta, sigma, F_k, tau_k)
% Anil Ramakrishna | akramakr@usc.edu
% This function computes the log likelihood for the independent
% continuous annotation model

    uniq_files = unique(fileid_array);
    pData = 0;
    d = size(annotations_mat{1}, 2); % number of annotations per data point

    for iter_file=1:numel(unique(fileid_array))
        cur_file_id = uniq_files(iter_file);
        anns_with_current_file = find(fileid_array == cur_file_id);
        
        for iter_data=1:numel(anns_with_current_file)
            cur_index = anns_with_current_file(iter_data);
            cur_ann_id = annotatorid_array(cur_index);
            
            matrix1 = annotations_mat{cur_index};vector1 = matrix1(:);
            t = size(matrix1,1);
            matrix2 = zeros(t, d);
            cur_a_star = a_star{cur_file_id};
            for iter_target_d=1:d
                cur_T_k=extract_T_k_from_vec(F_k(:,iter_target_d,cur_ann_id),t);
                matrix2(:,iter_target_d) = cur_T_k*cur_a_star(:,iter_target_d);
            end
            vector2 = matrix2(:);

            pAnGivenAstar = norm_pdf((vector1-vector2), 0, tau_k(cur_ann_id));
            pData = pData + pAnGivenAstar;
        end
        
        matrix1 = a_star{cur_file_id}; vector1 = matrix1(:);
        matrix2 = features_mat{cur_file_id} * theta; vector2 = matrix2(:);

        pAstarGivenX = norm_pdf((vector1-vector2), 0, sigma);
        pData = pData + pAstarGivenX;
    end
end

function [rval] = norm_pdf(X, mu, sigma)
    rval = sum(log(normpdf(X,mu,sqrt(sigma))));
end