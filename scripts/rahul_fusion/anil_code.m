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
addpath('..');
features_mat = get_features();
features_mat_cropped = features_mat{1}(1:N,:); % Need to only use one feature set too
features_mat{1} = features_mat_cropped;

save('data_matrix.mat', 'uniq_annotators', 'uniq_files', 'fileid_array', 'annotatorid_array', 'features_mat', 'annotations_mat');

expectation_maximization();

% a = cell(1,10);
% uniq_annotators = 1:10;
% uniq_files = 1;
% fileid_array = ones(10,1);
% annotatorid_array = ones(10,1);
% features_mat = cell(1);
% features_mat{1} = ones(300,2);
% annotations_mat = a;
% for i=1:10
%    annotations_mat{i} = annotations(i,:);
%    col_vec = annotations_mat{i}';
%    annotations_mat{i} = col_vec(1:300);
% end
% 
% save('data_matrix.mat', 'uniq_annotators', 'uniq_files', 'fileid_array', 'annotatorid_array', 'features_mat', 'annotations_mat');
% 
% expectation_maximization();
