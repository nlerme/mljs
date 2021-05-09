% Function performing the evaluation against available ground truths
function run_eval()
    % Clear and close
    close all;
    clear all;

    % Turns off some boring warnings
    warning('off', 'MATLAB:MKDIR:DirectoryExists');

    % Global variables
    results_dir            = ['..' filesep '..' filesep 'results_hyp']; % directory where segmentation are stored
    figures_dir            = ['..' filesep '..' filesep 'figures_hyp2']; % directory where figures are stored
    noise_densities        = 0.0:0.1:0.8;                               % list of noise densities
    seg_modes              = {'fp','coseg_matched','coseg_nearby'};     % segmentation approaches (fp, coseg_matched, coseg_nearby, etc.)
    seg_labels             = {'FP','MLJS-M','MLJS-N'};                  % labels of segmentation approaches (FP, MLJS-M, MLJS-N, etc.)
    recompute_measurements = 0;                                         % if true, recompute all segmentation measurements (accuracy, f-measure, etc.)
    recompute_input_figs   = 0;                                         % if true, recompute all color compositions and distribution of input data
    metric_names           = {'accuracy','f_measure'};                  % metric name (accuracy, f_measure, etc.)
    metric_ylabels         = {'ACC (in %)','FM (in %)'};                % metric labels on y-axis
    line_thickness         = 2;                                         % line thickness of generated figures
    font_size              = 14;                                        % font size of generated figures

    % We run the main function for every spectrum splitting strategy
    spectrum_modes = {'non-split','split','first_half','second_half'};
    for i=1:length(spectrum_modes)
        spectrum_mode = spectrum_modes{i};
        main();
    end

    function main()
        % We create the directory storing figures
        mkdir(figures_dir);

        % We allocate memory for storing all measurements
        all_results_aonr = {};
        all_results_raw  = {};

        % We loop over segmentation modes
        disp('---------------[ gathering measurements ]---------------');
        for i=1:length(seg_modes)
            seg_mode = seg_modes{i};
            disp(sprintf('+ %s', seg_mode));
            results_fn = [figures_dir filesep spectrum_mode '_' seg_mode '.mat'];

            % We either compute measurements or load them
            if recompute_measurements
                results = get_segmentation_measurements(results_dir, spectrum_mode, noise_densities, seg_mode);
                save(results_fn, 'results');
            else
                if ~exist(results_fn)
                    disp(['error: unable to find the file ''' results_fn '''']);
                    return;
                end

                load(results_fn);
            end

            % We store measurements in an array
            all_results_aonr{i} = results;
            all_results_raw{i}  = results;
        end

        % We get the scenes list, the dx list and the number of labels (assuming them equal for all approaches)
        scene_names = all_results_aonr{1}.scene_names;
        dx_names    = all_results_aonr{1}.dx_names;
        nb_labels   = all_results_aonr{1}.nb_labels;

        % We loop over noise densities
        if recompute_input_figs
            disp('---------------[ constructing illustrations of input data ]---------------');

            for i=1:length(noise_densities)
                noise_density = noise_densities(i);
                disp(sprintf('+ noise density %f', noise_density));

                % We loop over scenes
                for j=1:length(scene_names)
                    scene_name = scene_names{j};
                    disp(sprintf('  + scene ''%s''', scene_name));

                    % We set the labels list (either exhaustive or only present in the ground truth)
                    from_ground_truth = 1;
                    labels            = [];

                    if from_ground_truth
                        im_gt = load_ground_truth(all_results_aonr{1}.gt_root_dir, scene_name);

                        for k=min(im_gt(:)):max(im_gt(:))
                            if length(im_gt(im_gt==k))>0
                                labels = [labels,k];
                            end
                        end
                    else
                        labels = 1:nb_labels;
                    end

                    % We save color composition of mapped scores and distributions per scene and ground truth label
                    dx_root_dir = [all_results_aonr{1}.data_dir filesep 'probs+noise=' num2str(noise_density) '_real=1'];
                    im_probs    = load_probs(dx_root_dir, dx_names, scene_name, nb_labels);

                    cm = get_colormap();

                    for k=1:length(labels)
                        label = labels(k);
                        disp(sprintf('    + label %d', label));

                        im_res = double(zeros(size(im_probs,1),size(im_probs,2),3));

                        for l=1:size(im_probs,3)
                            color   = cm(l,:);
                            im_tmp1 = im_probs(:,:,l,label);
                            im_tmp2 = cat(3, im_tmp1*color(1), im_tmp1*color(2), im_tmp1*color(3));
                            im_res  = im_res + im_tmp2;
                        end

                        % Normalization
                        im_res(:,:,1) = im_res(:,:,1) / sum(cm(1:size(im_probs,3),1));
                        im_res(:,:,2) = im_res(:,:,2) / sum(cm(1:size(im_probs,3),2));
                        im_res(:,:,3) = im_res(:,:,3) / sum(cm(1:size(im_probs,3),3));

                        % We save the composed image
                        data_fn = [figures_dir filesep 'input_cc_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_scene=' scene_name '_label=' num2str(label) '.png'];
                        imwrite(im2double(im_res), data_fn);

                        % We save the distribution of mapped scores
                        h = figure;
                        hold on;
                        legend_str = {};
                        im_gt = load_ground_truth(all_results_aonr{1}.gt_root_dir, scene_name);
                        for l=1:size(im_probs,3)
                            im_tmp1    = im_probs(:,:,l,label);
                            im_tmp2    = im_tmp1(find(im_gt==label));
                            [counts,~] = hist(im_tmp2, 256);
                            plot(linspace(0,1,256),counts/sum(counts),'Color',cm(l,:));
                            s = strsplit(dx_names);
                            if strcmp(s{3},'full')
                                legend_str = {legend_str{:},s{1}};
                            elseif strcmp(s{3},'first')
                                legend_str = {legend_str{:},sprintf('%s^{fh}',s{1})};
                            elseif strcmp(s{3},'second')
                                legend_str = {legend_str{:},sprintf('%s^{sh}',s{1})};
                            else
                                disp('error: unknown dx_name');
                                return;
                            end
                        end
                        xlim([0,1]);
                        xlabel('Mapped score');
                        grid;
                        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
                        set(gca, 'linewidth', line_thickness);
                        set(gca, 'FontSize', font_size);
                        columnlegend(3, legend_str, 'Location', 'north', 'padding', 0.0, 'boxon');
                        fn = [figures_dir filesep 'input_dist_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_scene=' scene_name '_label=' num2str(label) '.png'];
                        saveas(h, fn);
                        close(h);
                        system(sprintf('mogrify -trim %s', fn));
                    end
                end
            end
        end

        % We loop over metric names
        for m=1:length(metric_names)
            metric_name = metric_names{m};
            disp(sprintf('------------[ constructing figures for metric %s ]------------', metric_name));

            % We loop over segmentation modes and average over noise realizations
            max_seg_names_size = 0;
            for i=1:length(seg_modes)
                seg_mode = seg_modes{i};
                measurements = getfield(all_results_aonr{i}, metric_name);
                all_results_aonr{i} = setfield(all_results_aonr{i}, metric_name, mean(measurements,2));
                max_seg_names_size = max(max_seg_names_size,length(all_results_aonr{i}.seg_names));
            end

            % We loop over noise densities
            best_measurements = double(zeros(length(noise_densities), ...
                                             length(scene_names)+1, ... % number of scenes + overall
                                             length(seg_modes), ...
                                             max_seg_names_size));

            for i=1:length(noise_densities)
                noise_density = noise_densities(i);
                disp(sprintf('+ noise density %f', noise_density));

                tab_fn = [figures_dir filesep 'tab_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_metric=' metric_name '.tex'];
                fp = fopen(tab_fn, 'w');

                % We loop over segmentation modes
                for k=1:length(seg_modes)
                    seg_mode = seg_modes{k};

                    % We loop over segmentation names
                    for l=1:length(all_results_aonr{k}.seg_names)
                        seg_name = all_results_aonr{k}.seg_names{l};

                        %if strcmp(seg_mode,'coseg_nearby') && ~strcmp(seg_name,'coseg')
                        %    continue;
                        %end

                        fprintf(fp, ' & %s-%s', seg_mode, seg_name);
                    end
                end
                fprintf(fp, '\\\\\\hline\n');

                % We loop over scenes
                for j=1:length(scene_names)
                    scene_name = scene_names{j};
                    str = sprintf('  + %s | ', scene_name);
                    fprintf(fp, '%s', scene_name);

                    % We loop over segmentation modes
                    for k=1:length(seg_modes)
                        seg_mode     = seg_modes{k};
                        measurements = getfield(all_results_aonr{k}, metric_name);

                        % We loop over segmentation names
                        for l=1:length(all_results_aonr{k}.seg_names)
                            seg_name = all_results_aonr{k}.seg_names{l};

                            %if strcmp(seg_mode,'coseg_nearby') && ~strcmp(seg_name,'coseg')
                            %    continue;
                            %end

                            if strcmp(seg_name,'coseg')
                                measurements2 = reshape(measurements(i,1,j,l,:,:),length(all_results_aonr{k}.beta_range),length(all_results_aonr{k}.gamma_range));
                            else
                                measurements2 = reshape(measurements(i,1,j,l,:,1),length(all_results_aonr{k}.beta_range),1);
                            end

                            % We look for the maximum measurement
                            [best_measurement,arg_measurements] = max(measurements2(:));
                            [arg1_measurements,arg2_measurements] = ind2sub(size(measurements2),arg_measurements);
                            beta = all_results_aonr{k}.beta_range(arg1_measurements);
                            gamma = all_results_aonr{k}.gamma_range(arg2_measurements);

                            % We append the maximum measurement to the array
                            best_measurements(i,j,k,l) = best_measurement;

                            % We complete the stdout message
                            str = [str sprintf('%s-%s=%f%% | ', seg_mode, seg_name, best_measurement)];
                            fprintf(fp, ' & %.2f', best_measurement);

                            % We save best segmentations
                            measurements3 = getfield(all_results_raw{k}, metric_name);
                            [~,real_index] = max(measurements3(i,:,j,l,arg1_measurements,arg2_measurements));

                            src_fn = [results_dir filesep 'spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_real=' num2str(real_index) filesep seg_mode '_beta=' sprintf('%f',beta) '_gamma=' sprintf('%f',gamma) filesep seg_mode '_' scene_name '_' seg_name '_seg_c.png'];
                            dst_fn = [figures_dir filesep 'hyp_best_seg_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_real=' num2str(real_index) '_seg-mode=' seg_mode '_scene=' scene_name '_seg-name=' seg_name '_metric=' metric_name '.png'];
                            copyfile(src_fn, dst_fn, 'f');

                            seg_fn  = [results_dir filesep 'spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_real=' num2str(real_index) filesep seg_mode '_beta=' sprintf('%f',beta) '_gamma=' sprintf('%f',gamma) filesep seg_mode '_' scene_name '_' seg_name '_seg.png'];
                            gt_fn   = all_results_aonr{k}.gt_root_dir;
                            im_seg  = uint8(imread(seg_fn));
                            im_gt   = load_ground_truth(all_results_aonr{k}.gt_root_dir, scene_name);
                            diff_fn = [figures_dir filesep 'hyp_best_diff_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_real=' num2str(real_index) '_seg-mode=' seg_mode '_scene=' scene_name '_seg-name=' seg_name '_metric=' metric_name '.png'];
                            imwrite(uint8(255*(im_seg~=im_gt)), diff_fn);

                            % We save the sensitivity maps
                            img_fn = [figures_dir filesep 'hyp_sensitivity_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_seg-mode=' seg_mode '_scene=' scene_name '_seg-name=' seg_name '_metric=' metric_name '.png'];
                            save_sensitivity_map(all_results_aonr{k}, measurements2, seg_mode, [arg1_measurements,arg2_measurements], best_measurement, img_fn, metric_ylabels{m});
                        end
                    end

                    disp(str);
                    fprintf(fp, '\\\\\\hline\n');
                end

                % We loop over segmentation modes
                str = '  + Overall | ';
                fprintf(fp, 'Overall');

                for k=1:length(seg_modes)
                    seg_mode     = seg_modes{k};
                    measurements = mean(getfield(all_results_aonr{k}, metric_name),3);

                    % We loop over segmentation names
                    for l=1:length(all_results_aonr{k}.seg_names)
                        seg_name = all_results_aonr{k}.seg_names{l};

                        %if strcmp(seg_mode,'coseg_nearby') && ~strcmp(seg_name,'coseg')
                        %    continue;
                        %end

                        if strcmp(seg_name,'coseg')
                            measurements2 = reshape(measurements(i,1,1,l,:,:),length(all_results_aonr{k}.beta_range),length(all_results_aonr{k}.gamma_range));
                        else
                            measurements2 = reshape(measurements(i,1,1,l,:,1),length(all_results_aonr{k}.beta_range),1);
                        end

                        % We look for the maximum measurement
                        [best_measurement,arg_measurements] = max(measurements2(:));
                        [arg1_measurements,arg2_measurements] = ind2sub(size(measurements2),arg_measurements);
                        beta = all_results_aonr{k}.beta_range(arg1_measurements);
                        gamma = all_results_aonr{k}.gamma_range(arg2_measurements);

                        % We append the maximum measurement to the array
                        best_measurements(i,length(scene_names)+1,k,l) = best_measurement;

                        % We complete the stdout message
                        str = [str sprintf('%s-%s=%f%% (beta=%f,gamma=%f) | ', seg_mode, seg_name, best_measurement, beta, gamma)];
                        fprintf(fp, ' & %.2f', best_measurement);

                        % We save the sensitivity maps
                        img_fn = [figures_dir filesep 'hyp_sensitivity_spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_seg-mode=' seg_mode '_scene=overall_seg-name=' seg_name '_metric=' metric_name '.png'];
                        save_sensitivity_map(all_results_aonr{k}, measurements2, seg_mode, [arg1_measurements,arg2_measurements], best_measurement, img_fn, metric_ylabels{m});
                    end
                end

                disp(str);
                fprintf(fp, '\\\\\\hline');
                fclose(fp);
            end

            % We save the noise robustness curves
            save_noise_robustness_curves({scene_names{:},'Overall'}, all_results_aonr, metric_name, best_measurements, metric_ylabels{m});
        end
    end

    function save_noise_robustness_curves( scene_names, results, metric_name, best_measurements, ylb )
        %for j=1:length(scene_names)
        for j=length(scene_names)
            scene_name = scene_names{j};
            h = figure;
            hold on;
            legend_str = {};
            count1 = 0;
            count2 = 1;
            cm = get_colormap();

            for k=1:length(seg_modes)
                seg_mode = seg_modes{k};
                seg_label = seg_labels{k};

                for l=1:length(results{k}.seg_names)
                    seg_name = results{k}.seg_names{l};

                    if strcmp(seg_name,'coseg')
                       legend_str = {legend_str{:},seg_label};
                       plot(noise_densities, best_measurements(:,j,k,l), 'Color', cm(count2,:));
                       count2 = count2+1;
                    else
                        if count1>=(length(results{k}.seg_names)-1)
                            s = strsplit(seg_name,'_');
                            if strcmp(s{3},'full')
                                legend_str = {legend_str{:},s{1}};
                            elseif strcmp(s{3},'first')
                                legend_str = {legend_str{:},sprintf('%s^{fh}',s{1})};
                            elseif strcmp(s{3},'second')
                                legend_str = {legend_str{:},sprintf('%s^{sh}',s{1})};
                            else
                                disp('error: unknown dx_name');
                                return;
                            end
                            plot(noise_densities, best_measurements(:,j,k,l), 'Color', cm(count2,:));
                            count2 = count2+1;
                        end
                        count1 = count1+1;
                    end

                    %labels = {labels{:},sprintf('%s-%s', seg_mode, seg_name)};
                    %plot(noise_densities, best_measurements(:,j,k,l));
                end
            end

            xlabel('Noise density');
            ylabel(ylb);
            ylim([0,100]);
            yticks(0:20:100);
            grid;
            fn = [figures_dir filesep 'hyp_noise_spectrum=' spectrum_mode '_scene=' lower(scene_name) '_metric=' metric_name '.png'];
            legend(legend_str, 'Location', 'bestoutside');
            set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
            set(gca, 'linewidth', line_thickness);
            set(gca, 'FontSize', font_size);
            saveas(h, fn);
            close(h);
            system(sprintf('mogrify -trim %s', fn));
        end
    end
    
    function save_sensitivity_map( results, measurements, seg_mode, arg_measurement, best_measurement, img_fn, ylb )
        if size(measurements,2)==1
            nb_ticks = 7;
            h = figure;
            hold on;

            plot(1:length(results.beta_range),measurements);

            beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
            beta_ticks2 = [0,results.beta_min_exponent:results.beta_max_exponent];
            set(gca, 'XTick', beta_ticks1);
            beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_common_ratio)))];
            set(gca, 'XTickLabel', beta_labels);
            xlabel('Weighting parameter \beta');
            xlim([1,length(results.beta_range)]);
            ylabel(ylb);

            %plot(arg_measurement(1), best_measurement, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
            %text(argmax(1), sprintf('beta=%.2f\nmax=%.2f',results.beta_range(argmax(1)),max_measurement));
            grid;

            set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
            set(gca, 'linewidth', line_thickness);
            set(gca, 'FontSize', font_size);

            saveas(gcf, img_fn);
            system(sprintf('mogrify -trim %s', img_fn));
            close(h);
        else
            nb_ticks = 7;
            h = figure;
            hold on;

            %imagesc(1:length(results.gamma_range),1:length(results.beta_range),measurements);
            imagesc(measurements);
            set(gca,'YDir','normal');

            gamma_ticks1 = round(linspace(1, length(results.gamma_range), nb_ticks));
            gamma_ticks2 = [0,results.gamma_min_exponent:results.gamma_max_exponent];
            set(gca, 'XTick', gamma_ticks1);
            gamma_labels = [num2str(0);cellstr(num2str(gamma_ticks2(gamma_ticks1(2:end))', sprintf('%.1f^{%%d}', results.gamma_common_ratio)))];
            set(gca, 'XTickLabel', gamma_labels);
            xlabel('Weighting parameter \gamma');

            beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
            beta_ticks2 = [0,results.beta_min_exponent:results.beta_max_exponent];
            set(gca, 'YTick', beta_ticks1);
            beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_common_ratio)))];
            set(gca, 'YTickLabel', beta_labels);
            ylabel('Weighting parameter \beta');

            axis equal tight;
            colorbar;
            colormap('gray');
            grid;

            %plot(arg_measurement(2), arg_measurement(1), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
            %text(arg_measurement(2), arg_measurement(1), sprintf('beta=%.2f\ngamma=%.2f\nmax=%.2f',results.gamma_range(arg_measurement(1)),results.beta_range(arg_measurement(2)),best_measurement));

            set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
            set(gca, 'linewidth', line_thickness);
            set(gca, 'FontSize', font_size);

            saveas(gcf, img_fn);
            system(sprintf('mogrify -trim %s', img_fn));
            close(h);
        end
    end
end
