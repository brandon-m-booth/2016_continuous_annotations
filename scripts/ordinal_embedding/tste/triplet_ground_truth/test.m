clear; close all; clc;

x = 1:5;
% X = [x' x'.^2];
X = x'.^2;
triplets = [];

for i = 1:5
    for j = 1:5
        for k = 1:5
            if i ~= j && i ~= k
                distance1 = pdist(X([i j]));
                distance2 = pdist(X([i k]));
                if distance1 < distance2
%                     disp([i j k]); disp(distance1); disp(distance2)
                    triplets = [triplets; [i j k]];
%                     pause
                end  
            end
        end
    end
end

Y = tste(triplets, 1, 0, 2);