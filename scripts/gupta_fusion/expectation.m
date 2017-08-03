function [a_star] = expectation(features_mat, ~, annotations_mat, annotatorid_array, fileid_array, ...
                t_k, theta)
% Anil Ramakrishna | akramakr@usc.edu            
% This function performs the Expectation-step. For each file, it uses current
% estimates for annotator parameters to compute a_star

    uniq_annotators = unique(annotatorid_array); 
    uniq_files = unique(fileid_array);
    k = numel(uniq_annotators);     % number of annotators
    m = numel(uniq_files);   % number of files
    p = size(features_mat{1}, 2); % number of features per data point
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    a_star = cell(m,1);
    
    for iter1=1:m
        data_points_with_cur_file_id = find(fileid_array == iter1);
        t = size(annotations_mat{data_points_with_cur_file_id(1)}, 1);
        cur_a_star = ones(t,d);

        for iter2=1:d
            XTX = zeros(t,t);
            XTy = zeros(t,1);

            for iter3=1:numel(data_points_with_cur_file_id)
                data_point_id = data_points_with_cur_file_id(iter3);
                cur_annotations_mat = annotations_mat{data_point_id};
                cur_annotator_id = annotatorid_array(data_point_id);

                y = cur_annotations_mat(:, iter2);
                X = extract_T_k_from_vec(squeeze(t_k(:, iter2, cur_annotator_id)), t);
                XTX = XTX + X'*X;
                XTy = XTy + X'*y;
            end

            XTX = XTX + eye(size(XTX,1));
            XTy = XTy + features_mat{iter1}*theta(:,iter2);

            if false  %Regularize 
                XTX = XTX + eye(size(XTX,1));
                XTy = XTy + reshape(mean(annotations_mat{data_points_with_cur_file_id}), t*d, 1);
            end

            if abs(rcond(XTX)) < 1e-15
                XTX = XTX + eye(size(XTX, 1));
            end

            %cur_a_star(:, iter2) = XTX\XTy;
            cur_a_star(:, iter2) = inv(XTX) * XTy;
        end 
        a_star{iter1} = cur_a_star;
    end
end
