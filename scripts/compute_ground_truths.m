import_annotations;

%%%%%%%%%%%%%%%%%%%
% Mariooryad method
%%%%%%%%%%%%%%%%%%%
estimate_lags_mariooryad;
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

mariooryad_evaldep_gt = mean(mariooryad_shifted_labels,1);

%%%%%%%%%%%%%%%%%%%
% CTW method - Runs out of memory :(
%%%%%%%%%%%%%%%%%%%
%estimate_lags_ctw;