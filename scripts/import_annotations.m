annotation_files_exp = '../trial1_data/annotation_30hz/Blue*label.csv';
subject_id_exp = '.*annotator(\d)+_label';

% Read in annotation data for each subject, task, session, and label type
if ~exist('annotations', 'var')
    [annotation_file_path,name,ext] = fileparts(annotation_files_exp);
    annotations_files = dir(annotation_files_exp);
    num_subjects = length(annotations_files);
    
    % Read in the raw annotations
    for i=1:num_subjects
        annotations_per_subject{i} = struct();
        subject_id = i-1;
        for file_index=1:length(annotations_files)
            file_name = annotations_files(file_index).name;
            file_token = regexp(file_name, subject_id_exp, 'tokens');
            file_subject_id = str2num(char(file_token{1}));
            if isempty(file_subject_id)
                disp(sprintf( 'Unable to match regular expression to file: %s. Skipping file', file_name));
                continue;
            end
            if file_subject_id == subject_id
                csv_data = ReadCsvFile(fullfile(annotation_file_path,file_name), ',');
                csv_data = CastToBestDataType(csv_data(2:end,2:end)); % Discard the header and time column

                if ~exist('annotations', 'var')
                    annotations = csv_data';
                else
                    % Make sure all annotations are the same length.
                    % Truncate the end of the time series when necessary.
                    if length(csv_data) > size(annotations, 2)
                        annotations = [annotations; csv_data(1:size(annotations,2))'];
                    elseif length(csv_data) < size(annotations, 2)
                        annotations = [annotations(:,1:length(csv_data)); csv_data'];
                    else
                        annotations = [annotations; csv_data'];
                    end
                end
            end
        end
    end
    
    % Create a label sequences variable (some methods need the data
    % presented in this way)
    label_sequences = cell(0);
    for i=1:size(annotations,1)
        label_sequences{length(label_sequences)+1} = annotations(i,:)';
    end
end