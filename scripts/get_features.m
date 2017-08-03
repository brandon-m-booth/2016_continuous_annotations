function feature_sequences = get_features(task_name, frequency)
    [pathstr, filename, ext] = fileparts(mfilename('fullpath'));
    features_file_exp = strcat(pathstr,'/../',task_name,'/AnnotationData/features_',num2str(frequency),'hz/*.csv');
    [features_file_path,name,ext] = fileparts(features_file_exp);
    feature_sequence_mat = [];
    features_files = dir(features_file_exp);
    for file_index=1:length(features_files)
        file_name = features_files(file_index).name;
        csv_data = ReadCsvFile(fullfile(features_file_path, file_name), ',');
        csv_data = CastToBestDataType(csv_data(2:end,2:end)); % Discard the header and time column
        feature_sequence_mat = [feature_sequence_mat, csv_data];
    end
    feature_sequences = cell(0);
    feature_sequences{1} = feature_sequence_mat;
end
