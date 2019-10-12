function [a_star] = expectation(m, features_mat, ~, annotations_mat, annotatorid_array, fileid_array, ...
                F_k, theta)
% Anil Ramakrishna | akramakr@usc.edu
% This function performs the Expectation-step. For each file, it uses current
% estimates for annotator parameters to compute a_star

    uniq_annotators = unique(annotatorid_array); 
    uniq_files = unique(fileid_array);
    k = numel(uniq_annotators);     % number of annotators
    p = size(features_mat{1}, 2); % number of features per data point
    d = size(annotations_mat{1}, 2); % number of annotations per data point
    a_star = cell(m,1);
    
    for iter_file=1:numel(uniq_files)
        cur_file_id = uniq_files(iter_file);
        data_points_with_cur_file_id = find(fileid_array == cur_file_id);
        t = size(annotations_mat{data_points_with_cur_file_id(1)}, 1);
        cur_a_star = ones(t,d);
        
        tmp_cell_array = annotations_mat(data_points_with_cur_file_id);
        average_annotations_mat = mean(cat(3,tmp_cell_array{:}), 3);
        
        for iter_target_d=1:d
            XTX = zeros(t,t);
            XTy = zeros(t,1);
            
            for iter_data=1:numel(data_points_with_cur_file_id)
                data_point_id = data_points_with_cur_file_id(iter_data);
                cur_annotations_mat = annotations_mat{data_point_id};
                cur_annotator_id = annotatorid_array(data_point_id);
                
                y = cur_annotations_mat(:, iter_target_d);
                X = extract_T_k_from_vec(squeeze(F_k(:, iter_target_d, cur_annotator_id)), t);
                XTX = XTX + X'*X;
                XTy = XTy + X'*y;
            end

            XTX = XTX + eye(size(XTX,1));
            XTy = XTy + features_mat{cur_file_id}*theta(:,iter_target_d);

            %Average annotation used as a regularizer - without this, over iterations 
            %a_star would get smooth, in a way capturing the variance entirely 
            %using F_k, leading to accurate inference of annotator outputs and 
            %in turn increasing log likelihood but poor performance in a_star prediction.
            if true  %Regularize 
                XTX = XTX + eye(size(XTX,1));
                XTy = XTy + average_annotations_mat(:, iter_target_d);
            end
            
            if abs(rcond(XTX)) < 1e-15
                fprintf('Correcting singular XTX in expectation\n');
                XTX = XTX + eye(size(XTX, 1));
            end

            cur_a_star(:, iter_target_d) = inv(XTX) * XTy;
        end 
        a_star{cur_file_id} = cur_a_star;
    end
end
