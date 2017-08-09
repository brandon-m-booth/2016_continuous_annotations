function run_pipeline_embedding()
   tasks = {'TaskA', 'TaskB'};
   ground_truths = {'simple_average', 'eval_dep', 'distort'};
   frequencies = [10.0];

   generate_embedding(tasks, ground_truths, frequencies);
   
   exit; % This scripts is intended to be executed from am external shell
end

function gt_file_path = get_ground_truth_file_path(task, ground_truth_name, frequency)
   gt_file_name = strcat(ground_truth_name,'_ground_truth_',num2str(frequency),'hz.csv');
   gt_file_path = cell2mat(strcat([cd],'/../',task,'/AnnotationData/ground_truth_baselines/',ground_truth_name,'/',gt_file_name));
end

function obj_file_path = get_objective_truth_file_path(task, frequency)
   obj_file_name = strcat(task,'_normalized_',num2str(frequency),'hz.csv');
   obj_file_path = cell2mat(strcat([cd],'/../',task,'/AnnotationData/objective_truth/',obj_file_name));
end

function output_folder = get_output_folder(task)
    output_folder = strcat([cd],'/../',char(task),'/AnnotationData/pipeline_results/');
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
end

function generate_embedding(tasks, ground_truths, frequencies)
    addpath([cd '/ordinal_embedding/tste/']);
    for task=tasks
        for ground_truth=ground_truths
            for freq=frequencies
                retain_percentage = 1.0;
                correct_percentage = 1.0;
                embedding_settings_str = strcat('retainp',num2str(100*retain_percentage),'_correctp',num2str(100*correct_percentage));
                embedding_settings_str = strrep(embedding_settings_str, '.', ',');
                interval_embedding_file_path = strcat(get_output_folder(task),char(ground_truth),'_constant_interval_embedding_',embedding_settings_str,'_',num2str(freq),'hz.csv');
                
                if ~exist(interval_embedding_file_path, 'file')
                    gt_file_path = get_ground_truth_file_path(task, ground_truth, freq);
                    obj_file_path = get_objective_truth_file_path(task, freq);
                    intervals_file_path = strcat(get_output_folder(task),char(ground_truth),'_constant_intervals_',num2str(freq),'hz.csv');
                    ordinateIntervals(interval_embedding_file_path, gt_file_path, obj_file_path, intervals_file_path, retain_percentage, correct_percentage);
                end
            end
        end
    end
end
