function tmp_script()
    for i=75:75:600
        create_synthetic_dataset(i);
        expectation_maximization;
        load('../../Data/matfiles/old_feats/Individual/data_matrix_synth.mat', 'a_star');
        tmp1=a_star{1};
        load('../../Data/results/Individual/estimatedParameters_synth.mat', 'a_star');
        tmp2=a_star{1};
        h=figure;
        plot(tmp1(:,1),'r'); hold on; plot(tmp2(:,2), 'b');
        title('a\_star with 600 dimensions');
        legend('Actual', 'Estimated');
        saveas(h,['~/GoogleDrive/tmp/ann_modeling_graphs/ind_a_star_' num2str(i)], 'fig');
        saveas(h,['~/GoogleDrive/tmp/ann_modeling_graphs/ind_a_star_' num2str(i)], 'jpg');
        close all;
    end
    return;
end