function [partition] = create_data_splits(num_folds, features_mat, annotations_mat, annotatorid_array, fileid_array)
    uniq_files = unique(fileid_array);
    if num_folds > numel(uniq_files)
        num_folds = numel(uniq_files);
    end
    
    cv_partition = cvpartition(numel(uniq_files), 'KFold', num_folds);
    partition = struct;
    partition.folds = [];
    for fold = 1:num_folds
        train_set = struct; test_set = struct;
        train_files = find(~cv_partition.test(fold));
        test_files = find(cv_partition.test(fold));
        
        test_inds = logical(zeros(size(annotatorid_array, 1), 1));
        for iter_test_f = 1:numel(test_files)
            test_f = test_files(iter_test_f);
            test_inds = test_inds | (fileid_array == test_f);
        end
        train_inds = ~test_inds;
        train_set.train_files = train_files;
        %train_set.a_star_gt = a_star;
        train_set.features_mat = features_mat;
        train_set.annotations_mat = annotations_mat(train_inds, :);
        train_set.annotatorid_array = annotatorid_array(train_inds,:);
        train_set.fileid_array = fileid_array(train_inds, :);
        
        test_set.test_files = test_files;
        test_set.annotations_mat = annotations_mat(test_inds, :);
        test_set.annotatorid_array = annotatorid_array(test_inds,:);
        test_set.fileid_array = fileid_array(test_inds, :);
        
        fold_struct = struct;
        fold_struct.train = train_set;
        fold_struct.test = test_set;
        partition.folds = [partition.folds; fold_struct];
    end
end