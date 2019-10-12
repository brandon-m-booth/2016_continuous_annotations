function verify_convexity()
% Anil Ramakrishna | akramakr@usc.edu
% This function tests the objective function if it fails the convexity
% condition between two points from the synthetic dataset and returns a
% message only if the test fails
    datadir = '../../Data/synthetic/matfiles/Independent/';
    load([datadir 'data_matrix_synth_1.mat']);
    load([datadir 'annotator_params_synth_1.mat']);
    a_star1 = a_star; a_k1 = annotations_mat; t_k1 = t_k; theta1 = theta;
    sigma_k1 = sigma_k; sigma_m1 = sigma_m;
    
    load([datadir 'data_matrix_synth_2.mat']);
    load([datadir 'annotator_params_synth_2.mat']);
    a_star2 = a_star; a_k2 = annotations_mat; t_k2 = t_k; theta2 = theta;
    sigma_k2 = sigma_k; sigma_m2 = sigma_m;
    
    obj1 = objective(fileid_array, annotatorid_array, a_k1, t_k1, sigma_k1, a_star1, features_mat, theta1, sigma_m1);
    obj2 = objective(fileid_array, annotatorid_array, a_k2, t_k2, sigma_k2, a_star2, features_mat, theta2, sigma_m2);
    
    convex = true;
    for i=0:0.0001:1
        cur_a_star = cell(size(a_star));
        for j=1:size(cur_a_star,1)
            cur_a_star{j} = i*a_star1{j} + (1-i)*a_star2{j};
        end
        cur_ann_mat = cell(size(a_k1));
        for j=1:size(cur_ann_mat,1)
            cur_ann_mat{j} = i*a_k1{j} + (1-i)*a_k2{j};
        end
        cur_t_k = t_k1*i + (1-i)*t_k2;
        cur_sigma_k = sigma_k1*i + (1-i)*sigma_k2;
        cur_sigma_m = sigma_m1*i + (1-i)*sigma_m2;
        cur_theta = theta1*i + (1-i)*theta2;
        obj3 = objective(fileid_array, annotatorid_array, cur_ann_mat, cur_t_k, cur_sigma_k, ...
            cur_a_star, features_mat, cur_theta, cur_sigma_m);
        fprintf('f(a):%f;f(b):%f;lambda:%f;f(a*lambda+(1-lambda)b):%f;lambda*f(a)+(1-lambda)*f(b):%f\n', obj1,obj2,i,obj3,(obj1*i + (1-i)*obj2));
        if convex
            if obj3 > obj1*i + (1-i)*obj2
                fprintf('Convexity condition violated at i=%d\n', i);
                return;
            end
        else
            if obj3 < obj1*i + (1-i)*obj2
                fprintf('Concavity condition violated at i=%d\n', i);
                return;
            end
        end
    end
end

function [obj_val] = objective(fileid_array, annotatorid_array, a_k, t_k, sigma_k, a_star, features_mat, theta, sigma_m)
    %ignoring numeric terms in the normal pdf ((2pisigma)^d/2) since
    %they're constant wrt parameters
    d = size(a_k{1}, 2); % number of annotations per data point
    k = size(t_k, 3);   % number of annotators
    
    obj_val = 0;
    for i=1:numel(sigma_m)
        cur_sigma_m = sigma_m(i);
        cur_file_id = i;
        curfile_anns = find(fileid_array == cur_file_id);
        cur_annotators = annotatorid_array(curfile_anns);
        cur_a_star = a_star{cur_file_id};
        t = size(cur_a_star, 1);
        for k=1:numel(cur_annotators)
            cur_sigma_k = sigma_k(k);
            cur_annotator_id = cur_annotators(k);
            cur_annfile_id = curfile_anns(k);
            matrix1 = a_k{cur_annfile_id}; vector1 = matrix1(:);
            matrix2 = zeros(t, d);
            for iter2=1:d
                cur_T_k = extract_T_k_from_vec(t_k(:,iter2,cur_annotator_id),t);
                matrix2(:,iter2) = cur_T_k*cur_a_star(:,iter2);
            end
            vector2 = matrix2(:);
            obj_val = obj_val + (1/cur_sigma_k)*(vector1 - vector2)'*(vector1 - vector2);
        end
        
        matrix1 = cur_a_star; vector1 = matrix1(:);
        matrix2 = features_mat{cur_file_id} * theta; vector2 = matrix2(:);
        obj_val = obj_val + (1/cur_sigma_m)*(vector1 - vector2)'*(vector1 - vector2);
    end
end