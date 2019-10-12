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