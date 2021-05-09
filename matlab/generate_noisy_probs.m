% This function generate probabilities from multiclass SVM scores, corrupted by some given amount of impulsive noise
function generate_noisy_probs()
    % Clear and close
    close all;
    clear all;

    % Turns off some boring warnings
    warning('off', 'MATLAB:MKDIR:DirectoryExists');

    % Global variables
    dx_names        = {'D0_scores_first_half', 'D0_scores_second_half', 'D1_scores_first_half', 'D1_scores_second_half', 'D2_scores_first_half', 'D2_scores_second_half'};
    %dx_names        = {'D0_scores_full', 'D1_scores_full', 'D2_scores_full'};
    scene_names     = {'Paper1_ss_ech', 'Paper2_ss_ech', 'Plastic1A_ss_ech', 'Plastic1B_ss_ech', 'Plastic2A_ss_ech', 'Plastic2B_ss_ech', 'Superposition_ss_ech'};
    data_dir        = ['..' filesep '..' filesep 'data'];
    scores_dir      = [data_dir filesep 'scores+noise=0'];
    thetas_fn       = [data_dir filesep 'thetas_split_spectrum.csv'];
    noise_densities = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8];
    nb_realizations = 3;

    %----------------------------------------------------------------------

    for noise_density=noise_densities
        disp(sprintf('+ noise density=%f', noise_density));
        probs_dir = [data_dir filesep 'probs+noise=' num2str(noise_density)];

        for k=1:nb_realizations
            disp(sprintf('  + realization %d', k));
            for scene_index=1:length(scene_names)
                scene_name = scene_names{scene_index};
                disp(sprintf('    + %s', scene_name));

                scores    = load_scores(scores_dir, dx_names, scene_name);
                nb_images = size(scores,3);
                nb_labels = size(scores,4);

                thetas = load_sigmoids_params(dx_names, thetas_fn, nb_images, nb_labels);
                all_probs = update_probs(scores, thetas);

                for i=1:length(dx_names)
                    disp(sprintf('      + %s', dx_names{i}));
                    my_dir = [probs_dir '_real=' num2str(k) filesep dx_names{i} filesep scene_names{scene_index}];
                    mkdir(my_dir);

                    for j=1:nb_labels
                        disp(sprintf('        + label %d', j));
                        fn = [my_dir filesep 'Score_SVM_' num2str(j)];
                        probs = imnoise(all_probs(:,:,i,j), 'salt & pepper', noise_density);
                        save(fn, 'probs');
                    end
                end
            end
        end
    end
end
