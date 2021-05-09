function run_hyp_non_tests()
    % Clear all variables and close all windows
    close all;
    clear all;

%     for real_index=[1,2,3]
%         if real_index>1
%             noise_densities = 0.1:0.1:0.8;
%         else
%             noise_densities = 0.0:0.1:0.8;
%         end
% 
%         for noise_density=noise_densities
%             main(noise_density, real_index);
%         end
%     end
    main(0.0, 1);

    function main( noise_density, real_index )
        % Turns off some boring warnings
        warning('off', 'MATLAB:MKDIR:DirectoryExists');

        % Global variables
        scene_names   = {'name'};
        data_dir      = ['..' filesep '..' filesep 'data'];
        spectrum_mode = 'split'; % can be either 'split', 'non-split', 'first_half' or 'second_half' (CAUTION: must be consistent with dx_names)
        dx_root_dir   = [data_dir filesep 'scores+noise=' num2str(noise_density) '_real=' num2str(real_index)];
        gt_root_dir   = [data_dir filesep 'ground_truths'];
        thetas_fn     = [data_dir filesep 'thetas_' spectrum_mode '_spectrum.csv'];
        seg_mode      = 'fp'; % can be either 'fp' (Naive Bayes), 'coseg_matched' (MLJS-M) or 'coseg_nearby' (MLJS-N)
        connectivity1 = 1; % intra-layer connectivity (0:Von Neumann neighborhoods, 1:Moore neighborhoods)
        connectivity2 = 0; % inter-layer connectivity (0:matched pixels, 1:matched pixels with Von Neumann neighborhoods, 2:matched pixels with Moore neighborhoods)
        results_dir   = ['..' filesep '..' filesep 'results' filesep 'spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_real=' num2str(real_index)];
        results_fn    = [results_dir filesep 'results_' seg_mode '.mat'];
        resolution    = [1.25,1.6]; % image resolution (horizontal,vertical)
        nb_labels     = 9;
        enable_debug  = 0;
        save_results  = 0;

        %----------------------------------------------------------------------

        if save_results
            % We create the directories storing results
            mkdir(results_dir);
        end

        % We set dx names (according to spectrum_mode variable)
        if strcmp(spectrum_mode,'first_half')
            dx_names = {'D0_scores_first_half', 'D1_scores_first_half', 'D2_scores_first_half'};
        elseif strcmp(spectrum_mode,'second_half')
            dx_names = {'D0_scores_second_half', 'D1_scores_second_half', 'D2_scores_second_half'};
        elseif strcmp(spectrum_mode,'split')
            dx_names = {'D0_scores_first_half', 'D0_scores_second_half', 'D1_scores_first_half', 'D1_scores_second_half', 'D2_scores_first_half', 'D2_scores_second_half'};
        elseif strcmp(spectrum_mode,'non-split')
            dx_names = {'D0_scores_full', 'D1_scores_full', 'D2_scores_full'};
        else
            disp('error: unknown spectrum mode');
            return;
        end

        % We set beta and gamma range
        if strcmp(seg_mode,'fp')
            beta_common_ratio  = 1.5;
            beta_min_exponent  = -16;
            beta_max_exponent  = +17;
            beta_range         = [0.0,beta_common_ratio.^(beta_min_exponent:beta_max_exponent)];
            %------------------------
            gamma_common_ratio = 0.0;
            gamma_min_exponent = 0;
            gamma_max_exponent = 0;
            gamma_range        = [0.0];
            %------------------------
        elseif strcmp(seg_mode,'coseg_matched')
            beta_common_ratio  = 1.5;
            beta_min_exponent  = -16;
            beta_max_exponent  = +17;
            beta_range         = [0.0,beta_common_ratio.^(beta_min_exponent:beta_max_exponent)];
            %------------------------
            gamma_common_ratio = 1.5;
            gamma_min_exponent = -16;
            gamma_max_exponent = +17;
            gamma_range        = [0.0,gamma_common_ratio.^(gamma_min_exponent:gamma_max_exponent)];
            %------------------------
        elseif strcmp(seg_mode,'coseg_nearby')
            beta_common_ratio  = 1.6;
            beta_min_exponent  = -23;
            beta_max_exponent  = +10;
            beta_range         = [0.0,beta_common_ratio.^(beta_min_exponent:beta_max_exponent)];
            %------------------------
            gamma_common_ratio = 1.6;
            gamma_min_exponent = -23;
            gamma_max_exponent = +10;
            gamma_range        = [0.0,gamma_common_ratio.^(gamma_min_exponent:gamma_max_exponent)];
            %------------------------
        else
            disp('error: unknown segmentation mode');
            return;
        end
        %beta_range = [1.5^3];
        %gamma_range = [1.5^-3];
        %beta_range = [1.6^-1];
        %gamma_range = [1.6^-4];

        % We create an empty array for storing energies
        all_E = double(zeros(length(beta_range),length(gamma_range),length(scene_names)));

        % We loop over instances and parameters
        for beta_index=1:length(beta_range)
            beta = beta_range(beta_index);
            disp(sprintf('+ beta=%f (noise density=%f,realization=%d)', beta, noise_density, real_index));

            for gamma_index=1:length(gamma_range)
                gamma = gamma_range(gamma_index);
                disp(sprintf('  + gamma=%f (noise density=%f,realization=%d)', gamma, noise_density, real_index));
                running_times = [];

                for scene_index=1:length(scene_names)
                    scene_name = scene_names{scene_index};

                    %----------------------------------------------------------

                    if save_results
                        results_dir2 = sprintf('%s%s%s_beta=%f_gamma=%f', results_dir, filesep, seg_mode, beta, gamma);
                        mkdir(results_dir2);
                    end

                    % We load the ground truth
                    %disp('+ loading ground truth');
                    im_gt = load_ground_truth(gt_root_dir, scene_name);

                    % We load estimates of regression coefficients
                    %disp('+ loading regression coefficients');
                    nb_images = length(dx_names);
                    thetas    = load_sigmoids_params(dx_names, thetas_fn, nb_images, nb_labels);

                    % We update probabilities
                    %probs = load_probs(dx_root_dir, dx_names, scene_name, nb_labels);
                    scores = load_scores(dx_root_dir, dx_names, scene_name);
                    probs = update_probs(scores, thetas);

                    % We update data costs
                    data_costs = update_data_costs(probs);

                    % We compute segmentation(s) either using FP or coseg approach
                    im_segs = [];
                    t = 0;

                    if strcmp(seg_mode, 'fp')
                        sigmasI = get_sigmasI_estimates(probs, connectivity1);
                        [im_seg,E,D,S,t] = run_seg(data_costs, probs, connectivity1, beta, nb_labels, sigmasI, resolution);
                        % For debug
                        if enable_debug
                            im_res = blend_images(zeros(size(im_seg)),im_seg,0.0);
                            figure, imshow(im_res,[]);
                        end
                    else
                        sigmasI = get_sigmasI_estimates(probs, connectivity1);
                        sigmasC = get_sigmasC_estimates(probs);

                        [im_segs,E,D,S,t] = run_coseg(data_costs, probs, connectivity1, connectivity2, beta*ones(1,nb_images), gamma*(1-eye(nb_images)), nb_labels, sigmasI, sigmasC, resolution);
                        im_seg = im_segs(:,:,nb_images+1);
                        % For debug
                        if enable_debug
                            im_res = blend_images(zeros(size(im_seg)),im_seg,0.0);
                            figure, imshow(im_res,[]);
                        end
                    end

                    % We compare resulting segmentation against ground truth
                    [accuracy,f_measure,~,~] = compare_segmentations(im_seg, im_gt, nb_labels);

                    % We display results
                    running_times = [running_times,t];
                    disp(sprintf('    + %s | time=%f secs, energy=%f (data-term=%f, smoothness-term=%f), accuracy=%f%%, f-measure=%f%%', scene_name, t, E, D, S, accuracy, f_measure));

                    % We save results
                    if save_results
                        if strcmp(seg_mode, 'fp')
                            seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_coseg_seg.png'];
                            imwrite(im_seg, seg_fn);
                            seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_coseg_seg_c.png'];
                            imwrite(blend_images(zeros(size(im_seg)),im_seg,0.0), seg_fn);
                        else
                            for i=1:nb_images
                                seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_' dx_names{i} '_seg.png'];
                                imwrite(im_segs(:,:,i), seg_fn);
                                seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_' dx_names{i} '_seg_c.png'];
                                imwrite(blend_images(zeros(size(im_seg)),im_segs(:,:,i),0.0), seg_fn);
                            end
                            seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_coseg_seg.png'];
                            imwrite(im_segs(:,:,nb_images+1), seg_fn);
                            seg_fn = [results_dir2 filesep seg_mode '_' scene_name '_coseg_seg_c.png'];
                            imwrite(blend_images(zeros(size(im_seg)),im_segs(:,:,nb_images+1),0.0), seg_fn);
                        end
                    end

                    all_E(beta_index,gamma_index,scene_index) = E;

                    %----------------------------------------------------------
                end

                disp('    -------------------------------');
                disp(sprintf('    + time -> %f+/-%f (min=%f,  max=%f)', mean(running_times), std(running_times), min(running_times), max(running_times)));
            end
        end

        if save_results
            save(results_fn, ...
                 'dx_names', 'scene_names', 'dx_root_dir', 'data_dir', ...
                 'gt_root_dir', 'thetas_fn', 'all_E', 'nb_labels', ...
                 'seg_mode', 'connectivity1', 'connectivity2', 'resolution', ...
                 'beta_common_ratio', 'beta_min_exponent', 'beta_max_exponent', 'beta_range', ...
                 'gamma_common_ratio', 'gamma_min_exponent', 'gamma_max_exponent', 'gamma_range');
        end
    end
end
