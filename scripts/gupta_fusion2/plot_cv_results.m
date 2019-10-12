function plot_cv_results()
    data_file = '../../Data/synthetic_color_change/matfiles/data_matrix.mat';
    result_file = '../../Data/synthetic_color_change/results/Independent/estimatedParameters_windowsize';
    figures_dir = '../../Data/synthetic_color_change/results/Independent/figures/';
    
    load(data_file, 'a_star');
    t = size(a_star{1},1);
    a_star_orig = cell2mat(a_star);
    W_list = [(1:10)'; (15:5:25)'; (30:10:90)'; (100:100:t)'];
    ccc_vec = [];
    corr_vec = [];
    
    for i=1:numel(W_list)
        cur_W = W_list(i);
        load([result_file num2str(cur_W) '.mat'], 'a_star');
        a_star = cell2mat(a_star);
        ccc_vec = [ccc_vec; ccc(a_star_orig(:), a_star(:))];
        corr_vec = [corr_vec; corr(a_star_orig(:), a_star(:))];
    end
    
    bar(ccc_vec);
    title('ccc between original and estimated a\_star for varying W');
    set(gca, 'XTick', 1:numel(W_list));
    set(gca, 'XTickLabel', W_list);
    saveas(gcf, [figures_dir 'concordance_correlations'], 'jpg');
    close all;
    
    bar(corr_vec);
    title('Correlation between original and estimated a\_star for varying W');
    set(gca, 'XTick', 1:numel(W_list));
    set(gca, 'XTickLabel', W_list);
    saveas(gcf, [figures_dir 'correlations'], 'jpg');
    close all;
end

function ret_val = ccc(x, y)
    mu_x = mean(x); sigma_x = std(x);
    mu_y = mean(y); sigma_y = std(y);
    rho = corr(x, y);
    cov_xy = cov(x, y);
    sigma_xy = cov_xy(1,2);
    
    %ret_val = (2 * rho * sigma_x * sigma_y) / (sigma_x^2 + sigma_y^2 +
    %(mu_x - mu_y)^2);      // This expression is for population params
    
    ret_val = (2 * sigma_xy) / (sigma_x^2 + sigma_y^2 + (mu_x - mu_y)^2);
end