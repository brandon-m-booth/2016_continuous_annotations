function [const_intervals] = compute_constant_intervals(sig)
    shallowness_threshold = 0.003;
    min_const_frames = 15;
    
    [maxima, max_idx] = findpeaks(sig);
    [minima, min_idx] = findpeaks(-sig);
    %optima = [maxima, minima];
    opt_idx = [max_idx; min_idx];
    
    %plot(sig, 'b-'); hold on; plot(opt_idx, sig(opt_idx), 'ro');
    
    % Find local optima satisfying constraints
    const_idx = [];
    sig_diff = diff(sig);
    diff_threshold = shallowness_threshold/min_const_frames;
    for i = 1:length(opt_idx)
        idx = opt_idx(i);
        lower_idx = max(1, idx-min_const_frames);
        upper_idx = min(length(sig_diff), idx+min_const_frames);
        left_diff_max = max(abs(sig_diff(lower_idx:idx-1)));
        right_diff_max = max(abs(sig_diff(idx:upper_idx)));
        if left_diff_max < diff_threshold || right_diff_max < diff_threshold
            const_idx = [const_idx, idx];
        end
    end
    
    const_idx = sort(const_idx);
    %plot(sig, 'b-'); hold on; plot(const_idx, sig(const_idx), 'ro');
    
    % Collapse redundant optima
    const_intervals = [];
    const_min_idx = NaN;
    const_max_idx = NaN;
    for i = 1:length(const_idx)
        idx = const_idx(i);
        if isnan(const_min_idx)
            const_min_idx = idx;
            const_max_idx = idx;
        else
            sig_diff = abs((sig(idx)-sig(const_min_idx)));
            if sig_diff < shallowness_threshold
                const_max_idx = idx;
            else
                const_intervals = [const_intervals; [const_min_idx, const_max_idx]];
                const_min_idx = idx;
                const_max_idx = idx;
            end
        end
    end
    
    %plot(sig, 'b-'); hold on;
    %for i = 1:size(const_intervals,1)
    %   plot(const_intervals(i,:), sig(const_intervals(i,:)), 'r-o'); 
    %end
    
    % Expand constant intervals on the signal under shallowness constraints
    for i = 1:size(const_intervals,1)
        lower_idx = const_intervals(i,1);
        upper_idx = const_intervals(i,2);
        lower_sig = sig(lower_idx);
        upper_sig = sig(upper_idx);
        for j = lower_idx:-1:1
            if abs(sig(j)-lower_sig) < shallowness_threshold
                lower_idx = j;
            else
                break;
            end
        end
        for j = upper_idx:1:length(sig)
            if abs(sig(j)-upper_sig) < shallowness_threshold
                upper_idx = j;
            else
                break;
            end
        end
        const_intervals(i,:) = [lower_idx, upper_idx];
    end
    
    plot(sig, 'b-'); hold on;
    for i = 1:size(const_intervals,1)
       plot(const_intervals(i,:), sig(const_intervals(i,:)), 'r-o'); 
    end
end