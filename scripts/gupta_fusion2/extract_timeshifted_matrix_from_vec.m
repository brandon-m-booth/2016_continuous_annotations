function [timeshifted_matrix]=extract_timeshifted_matrix_from_vec(vec,m,n)
    assert(numel(vec)==m)
    timeshifted_matrix = zeros(m,n);
    for iter2=1:m
        tmp_vec = zeros(1,n);
        num_elements = min([iter2,n]);
        %Match a_star with reshaped F_k
        start_pos = max(iter2 - num_elements + 1, 1); end_pos=iter2;
        element_vec = vec(start_pos:end_pos);
        start_pos=n-num_elements+1; end_pos=n;
        tmp_vec(start_pos:end_pos) = element_vec;
        timeshifted_matrix(iter2,:) = tmp_vec;
    end
end