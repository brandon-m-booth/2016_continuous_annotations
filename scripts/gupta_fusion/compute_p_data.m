function [pData] = compute_p_data(features_mat, annotations_mat, annotatorid_array, ...
            fileid_array, a_star, theta, sigma_m, t_k, sigma_k)
% Anil Ramakrishna | akramakr@usc.edu
% This function computes the negative log likelihood for the independent
% continuous annotation model

    pData = 0;
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    k = size(t_k, 4);   % number of annotators
    
    num_annotations = numel(fileid_array);
    
    for iter1=1:num_annotations
        pAnGivenAstar = 0;
        pAstarGivenX = 0;
    
        cur_annotator_id = annotatorid_array(iter1);
        cur_file_id = fileid_array(iter1);
        
        matrix1 = annotations_mat{iter1};vector1 = matrix1(:);
        t = size(matrix1,1);
        matrix2 = zeros(t, d);
        cur_a_star = a_star{cur_file_id};
        for iter2=1:d
            cur_T_k=extract_T_k_from_vec(t_k(:,iter2,cur_annotator_id),t);
            matrix2(:,iter2) = cur_T_k*cur_a_star(:,iter2);
        end
        vector2 = matrix2(:);
        
        for iter2=1:numel(vector1)
            pAnGivenAstar = pAnGivenAstar + (find_normpdf(vector1(iter2)-vector2(iter2), 0, ...
                sigma_k(cur_annotator_id)));
        end
        
        matrix1 = a_star{cur_file_id}; vector1 = matrix1(:);
        matrix2 = features_mat{cur_file_id} * theta; vector2 = matrix2(:);
        for iter2=1:numel(vector1)
            pAstarGivenX = pAstarGivenX + (find_normpdf(vector1(iter2)-vector2(iter2), 0, ...
                sigma_m(cur_file_id)));
        end
%        pData = pData + pAnGivenAstar/(t*d) + pAstarGivenX/(t*d);
        pData = pData + pAnGivenAstar + pAstarGivenX;
    end
%    pData = pData / (num_annotations);
end

function [rval] = find_normpdf(x, mu, sigma)
    if false
        if sum(x) == 0
            rval = numel(x);
        else
            rval = Inf;
        end
    else
        rval = log(normpdf(x, mu, sigma));
    end
end
