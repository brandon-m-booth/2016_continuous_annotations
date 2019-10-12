function check_ifsorted(vec)
    if issorted(vec) 
        1
    else
        for i=2:numel(vec)
            if vec(i) < vec(i-1)
                fprintf('Likelihood decreased at iter: %d\n', i);
                break;
            end
        end
    end
end