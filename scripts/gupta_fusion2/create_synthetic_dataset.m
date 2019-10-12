function create_synthetic_dataset(varargin)
% Anil Ramakrishna | akramakr@usc.edu
% This function loads existing features from a data corpus and creates
% synthetic data assuming the independent annotators model

    dataDir = '../../Data/synthetic/matfiles/Independent/';
    load([dataDir 'data_matrix.mat'], 'features_mat');
    
    if nargin == 0
        num_dims = 350;
    else
        num_dims = varargin{1};
    end
    features_mat = features_mat(1:num_dims,:,:);
    
    t=size(features_mat, 1);
    p=size(features_mat, 2);
    m=size(features_mat, 3);
    k=6; d=2; W=8;
    noise_scaling_factor = 0.1;
    
    features_mat = squeeze(num2cell(features_mat, [1 2]));
    
    sigma = rand*noise_scaling_factor;
    a_star = [{}];
    cur_a_star = rand(t,d);
    for iter1=1:m
        cur_a_star(1,:) = rand(1,d)*0.005;
        for iter2=2:t
            cur_a_star(iter2,:) = cur_a_star(iter2-1,:) + -0.01+rand(1,d)*0.02;
        end
        a_star = [a_star; {cur_a_star}];
    end
    
    XbarX = zeros(p, p);
    Xbary = zeros(p, d);

    %Estimate theta
    for iter1=1:m
        cur_a_star = a_star{iter1};
        cur_features_mat = features_mat{iter1};
        
        XbarX = XbarX + (cur_features_mat' * cur_features_mat);
        Xbary = Xbary + (cur_features_mat' * cur_a_star);
    end
    if abs(rcond(XbarX)) < 1e-15
        XbarX = XbarX + eye(p);
    end
    
    theta = inv(XbarX) * Xbary;

    %Recompute a_star closer to f(X|theta)
    for iter1=1:m
        a_star{iter1} = features_mat{iter1}*theta + normrnd(0, sigma, t, d);
    end
    
    F_k = rand(W,d,k);
    for iter1=1:k
        for iter2=1:d
            tmp_vec = rand(1, W);
            %tmp_vec = tmp_vec / sum(tmp_vec);
            F_k(:, iter2, iter1) = tmp_vec;
        end
    end

    tau_k = rand(k,1)*noise_scaling_factor;
    annotations_mat = cell(k*m,1);
    fileid_array = zeros(k*m,1);
    annotatorid_array = zeros(k*m,1);
    for iter1=1:m
        for iter2=1:k
            cur_a_star = a_star{iter1}; 
            t = size(cur_a_star, 1);  
            d = size(cur_a_star, 2);
            cur_index = (iter1-1)*k + iter2;
            fileid_array(cur_index)=iter1;
            annotatorid_array(cur_index)=iter2;
            cur_ann_mat = rand(t,d);
            for iter3=1:d
                cur_T_k = extract_T_k_from_vec(F_k(:,iter3,iter2),t);
                cur_ann_mat(:,iter3) = cur_T_k*cur_a_star(:,iter3) + normrnd(0,tau_k(iter2),t,1);
            end
            annotations_mat{cur_index} = cur_ann_mat;
        end
    end

    uniq_annotators = unique(annotatorid_array);
    uniq_files = unique(fileid_array);

    save([dataDir 'data_matrix_synth.mat'], 'a_star', 'annotations_mat', 'uniq_annotators', 'uniq_files', 'annotatorid_array', 'features_mat', 'fileid_array');
    save([dataDir 'annotator_params_synth.mat'], 'F_k', 'tau_k', 'sigma', 'theta');
end
