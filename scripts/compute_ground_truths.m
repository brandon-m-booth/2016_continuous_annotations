function ground_truth = compute_ground_truths(task_name, ground_truth_name, frequency)
    ground_truth = [];
    
	[annotations, label_sequences] = import_annotations(task_name, frequency);
    if isempty(annotations)
        return; 

    if strcmp(ground_truth_name, 'simple_average')
        ground_truth = mean(annotations,1);
    
    elseif strcmp(ground_truth_name,'eval_dep')
        addpath(genpath([cd '/mariooryad_lag_estimation']))
        feature_sequences = get_features(task_name, frequency);
        max_lag_frames = 10*frequency;
        mariooryad_lags = estimate_lags_mariooryad(annotations, feature_sequences, label_sequences, max_lag_frames);
        shifted_labels = cell(1,length(label_sequences));
        min_length = inf;
        for label_seq_idx = 1:length(label_sequences)
            lag = mariooryad_lags.annotator_lags{label_seq_idx}(1);
            shifted_labels{label_seq_idx} = label_sequences{label_seq_idx}(lag:end);
            if length(shifted_labels{label_seq_idx}) < min_length
            min_length = length(shifted_labels{label_seq_idx});
            end
        end

        % Make all label sequences as long as the shortest one
        mariooryad_shifted_labels = zeros(length(label_sequences), min_length);
        for label_seq_idx = 1:length(label_sequences)
            shifted_labels{label_seq_idx} = shifted_labels{label_seq_idx}(1:min_length);
            mariooryad_shifted_labels(label_seq_idx,:) = shifted_labels{label_seq_idx};
        end

        ground_truth = mean(mariooryad_shifted_labels,1);

    elseif strcmp(ground_truth_name,'distort')
        addpath(genpath([cd '/gupta_fusion']))
        feature_sequences = get_features(task_name, frequency);
        ground_truth = gupta_fusion(annotations, feature_sequences);
    
    elseif strcmp(ground_truth_name,'distort2')
        % First time-align the sequences, then run distort2
        addpath(genpath([cd '/mariooryad_lag_estimation']))
        feature_sequences = get_features(task_name, frequency);
        max_lag_frames = 10*frequency;
        mariooryad_lags = estimate_lags_mariooryad(annotations, feature_sequences, label_sequences, max_lag_frames);
        shifted_labels = cell(1,length(label_sequences));
        min_length = inf;
        for label_seq_idx = 1:length(label_sequences)
            lag = mariooryad_lags.annotator_lags{label_seq_idx}(1);
            shifted_labels{label_seq_idx} = label_sequences{label_seq_idx}(lag:end);
            if length(shifted_labels{label_seq_idx}) < min_length
            min_length = length(shifted_labels{label_seq_idx});
            end
        end

        % Make all label sequences as long as the shortest one
        mariooryad_shifted_labels = zeros(length(label_sequences), min_length);
        for label_seq_idx = 1:length(label_sequences)
            shifted_labels{label_seq_idx} = shifted_labels{label_seq_idx}(1:min_length);
            mariooryad_shifted_labels(label_seq_idx,:) = shifted_labels{label_seq_idx};
        end
        
        % Truncate the features to align with the shifted labels
        shifted_features = cell(1,length(feature_sequences));
        for feature_seq_idx = 1:length(feature_sequences)
            shifted_features{feature_seq_idx} = feature_sequences{feature_seq_idx}(1:min_length,:);
        end
        
        addpath(genpath([cd '/gupta_fusion2']))
        %feature_sequences = get_features(task_name, frequency);
        %ground_truth = gupta_fusion2(annotations, feature_sequences);
        ground_truth = gupta_fusion2(mariooryad_shifted_labels, shifted_features)
        
    elseif strcmp(ground_truth_name, 'ctw')
        %%%%%%%%%%%%%%%%%%%
        % CTW method - Runs out of memory :(
        %%%%%%%%%%%%%%%%%%%
        %estimate_lags_ctw;
        disp 'CTW not implemented';
    else
        disp 'Method not implemented';
    end
end
