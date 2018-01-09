function run_pipeline_gt_tv()
   % Handle simulated tasks
   tasks = {'TaskA', 'TaskB'};
   ground_truths = {'simple_average', 'eval_dep', 'distort'};
   tv_params = [0.05, 0.05, 0.05];
   eps_params = [10.5, 10.5, 10.5];
   frequencies = [10.0];

   generate_ground_truth_baselines(tasks, ground_truths, frequencies)
   generate_tv_baselines(tasks, ground_truths, frequencies, tv_params, eps_params)

   % Handle AVEC tasks
   tasks = {'TaskAvecArousalTrain1', 'TaskAvecArousalTrain2', 'TaskAvecArousalTrain3', 'TaskAvecArousalTrain4', 'TaskAvecArousalTrain5', 'TaskAvecArousalTrain6', 'TaskAvecArousalTrain7', 'TaskAvecArousalTrain8', 'TaskAvecArousalTrain9', 'TaskAvecArousalDev1', 'TaskAvecArousalDev2', 'TaskAvecArousalDev3', 'TaskAvecArousalDev4', 'TaskAvecArousalDev5', 'TaskAvecArousalDev6', 'TaskAvecArousalDev7', 'TaskAvecArousalDev8', 'TaskAvecArousalDev9', 'TaskAvecValenceTrain1', 'TaskAvecValenceTrain2', 'TaskAvecValenceTrain3', 'TaskAvecValenceTrain4', 'TaskAvecValenceTrain5', 'TaskAvecValenceTrain6', 'TaskAvecValenceTrain7', 'TaskAvecValenceTrain8', 'TaskAvecValenceTrain9', 'TaskAvecValenceDev1', 'TaskAvecValenceDev2', 'TaskAvecValenceDev3', 'TaskAvecValenceDev4', 'TaskAvecValenceDev5', 'TaskAvecValenceDev6', 'TaskAvecValenceDev7', 'TaskAvecValenceDev8', 'TaskAvecValenceDev9'};
   ground_truths = {'simple_average'};
   tv_params = [0.005];
   eps_params = [5.5];
   frequencies = [25.0];

   generate_ground_truth_baselines(tasks, ground_truths, frequencies)
   generate_tv_baselines(tasks, ground_truths, frequencies, tv_params, eps_params)
   
   exit; % This scripts is intended to be executed from am external shell
end

function gt_file_path = get_ground_truth_file_path(task, ground_truth_name, frequency)
   gt_file_name = strcat(ground_truth_name,'_ground_truth_',num2str(frequency),'hz.csv');
   gt_file_path = cell2mat(strcat([cd],'/../annotation_tasks/',task,'/AnnotationData/ground_truth_baselines/',ground_truth_name,'/',gt_file_name));
end

function output_folder = get_output_folder(task)
    output_folder = strcat([cd],'/../annotation_tasks/',char(task),'/AnnotationData/pipeline_results/');
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
end

function generate_ground_truth_baselines(tasks, ground_truths, frequencies)
   for task=tasks
      for ground_truth=ground_truths
         for freq=frequencies
            gt_file_path = get_ground_truth_file_path(task, ground_truth, freq);
            if ~exist(gt_file_path, 'file')
               gt = compute_ground_truths(task{1}, ground_truth{1}, freq);
               if isempty(gt)
                  continue; 
               end
                   
               header = {'Time_sec','Data'};
               times = 0:1.0/freq:length(gt)/freq;
               times = times(1:length(gt));
               time_gt_mat = [reshape(times,[length(times),1]), reshape(gt,[length(gt),1])];
               write_csv_file(gt_file_path, time_gt_mat, header);
            end
         end
      end
   end
end

function generate_tv_baselines(tasks, ground_truths, frequencies, tv_params, eps_params)
   for task=tasks
      for i=1:length(ground_truths)
         ground_truth = ground_truths(i);
         tv_param = tv_params(i);
         eps_param = eps_params(i);
         for freq=frequencies
            gt_file_path = get_ground_truth_file_path(task, ground_truth, freq);
            tv_file_path = strcat(get_output_folder(task),char(ground_truth),'_tv_',num2str(freq),'hz.csv');
            if exist(gt_file_path, 'file') && ~exist(tv_file_path, 'file')
               gt_data = read_csv_file(gt_file_path, ',');
               header = gt_data(1,:);
               times = str2num(char(gt_data(2:end,1)));
               gt_data = str2num(char(gt_data(2:end,2)));
               tv = tv_1d(gt_data, tv_param, eps_param);
               time_tv_mat = [times,tv];
               write_csv_file(tv_file_path, time_tv_mat, header);
            end
         end
      end
   end
end
