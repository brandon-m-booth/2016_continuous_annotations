function fusion = gupta_fusion(annotations, features_mat)
    rng(0);

    % Vars
    N = min(size(annotations,2), size(features_mat{1},1));
    num_annotations = size(annotations,1);
    uniq_annotators = 1:num_annotations;
    uniq_files = 1;
    fileid_array = ones(num_annotations,1);

    % Annotations
    annotatorid_array = 1:num_annotations;
    annotations_mat = cell(1,num_annotations);
    for i=1:num_annotations
        annotations_mat{i} = annotations(i,:);
    end
    for i=1:num_annotations
        col_vec = annotations_mat{i};
        annotations_mat{i} = col_vec(1:N)';
    end

    % Features
    features_mat_cropped = features_mat{1}(1:N,:); % Need to only use one feature set too
    features_mat{1} = features_mat_cropped;
    
    % Add bias vector (ones) to features and N(0,1) normalize
    for i=1:size(features_mat{1},2)
        features_mat{1}(:,i) = (features_mat{1}(:,i)-mean(features_mat{1}(:,i)))/std(features_mat{1}(:,i));
    end
    features_mat{1}(:,size(features_mat{1},2)+1) = ones(N,1);

    save('data_matrix.mat', 'uniq_annotators', 'uniq_files', 'fileid_array', 'annotatorid_array', 'features_mat', 'annotations_mat');

    [a_star, sigma_m, theta, t_k, sigma_k, counter, features_mat] = expectation_maximization();
    fusion = a_star{1};
end
