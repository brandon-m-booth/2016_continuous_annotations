function [T_k]=extract_T_k_from_vec(t_vec,t)
    W=numel(t_vec);
    T_k = zeros(t,t);
    for iter2=1:t
        tmp_vec = zeros(1,t);
        num_elements = min(iter2,W);
        %Slide the filter vector so that last element is front of filter
        start_pos = W - num_elements + 1; end_pos = W;
        element_vec = t_vec(start_pos:end_pos); 
        start_pos = max(iter2-W+1,1); end_pos=iter2;
        tmp_vec(start_pos:end_pos) = element_vec;
        T_k(iter2,:) = tmp_vec;
    end
end