% Function returning segmentation measurements
% 
% Input arguments:
%   - results_dir     : directory where resulting segmentations are stored
%   - spectrum_mode   : way of how spectrum is handled (split, non-split, first_half, second_half, etc.)
%   - noise_densities : list of noise densities
%   - seg_mode        : segmentation approach (fp, coseg_matched, coseg_nearby, etc.)
% 
% Output arguments:
%   - out.accuracy           : accuracy measurements against ground truth (in [0,100])
%   - out.f_measure          : f-measure measurements against ground truth (in [0,100])
%   - out.scene_names        : list of scene names
%   - out.seg_names          : list of segmentation names
%   - out.dx_names           : list of dx names
%   - out.data_dir           : data directory
%   - out.beta_min_exponent  : minimum exponent of beta
%   - out.beta_max_exponent  : maximum exponent of beta
%   - out.beta_common_ratio  : common ratio of beta
%   - out.beta_range         : range values of beta
%   - out.gamma_min_exponent : minimum exponent of gamma
%   - out.gamma_max_exponent : maximum exponent of gamma
%   - out.gamma_common_ratio : common ratio of gamma
%   - out.gamma_range        : range values of gamma 
%   - out.nb_labels          : number of labels
%   - out.gt_root_dir        : ground truths directory
% 
function out = get_segmentation_measurements( results_dir, spectrum_mode, noise_densities, seg_mode )
    out = struct();

    % We compute the maximum number of noise realizations
    max_nb_realizations = 0;

    for noise_density=noise_densities
        my_dirs = get_matching_dirs(results_dir, ['spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_.*']);
        max_nb_realizations = max(max_nb_realizations,length(my_dirs));
    end

    % We loop over noise densities
    count = 1;

    for i=1:length(noise_densities)
        noise_density = noise_densities(i);
        disp(sprintf('  + noise density %f', noise_density));
        my_dirs = get_matching_dirs(results_dir, ['spectrum=' spectrum_mode '_noise=' num2str(noise_density) '_.*']);
        m_acc = [];
        m_fm = [];

        % We loop over the available realizations of the current noise density
        for j=1:length(my_dirs)
            disp(sprintf('    + realization %d', j));
            results_fn = [my_dirs{j} filesep 'results_' seg_mode '.mat'];
            results    = load(results_fn);

            if count==1
                if strcmp(seg_mode, 'fp')
                    out.seg_names = {'coseg'};
                else
                    out.seg_names = {'coseg',results.dx_names{:}};
                end

                out.data_dir           = results.data_dir;
                out.scene_names        = {results.scene_names{7}};
                out.dx_names           = results.dx_names;
                out.beta_min_exponent  = results.beta_min_exponent;
                out.beta_max_exponent  = results.beta_max_exponent;
                out.beta_common_ratio  = results.beta_common_ratio;
                out.beta_range         = results.beta_range;
                out.gamma_min_exponent = results.gamma_min_exponent;
                out.gamma_max_exponent = results.gamma_max_exponent;
                out.gamma_common_ratio = results.gamma_common_ratio;
                out.gamma_range        = results.gamma_range;
                out.accuracy           = double(zeros(length(noise_densities), ...
                                                      max_nb_realizations, ...
                                                      length(out.scene_names), ...
                                                      length(out.seg_names), ...
                                                      length(out.beta_range), ...
                                                      length(out.gamma_range)));
                out.f_measure          = out.accuracy;
                out.nb_labels          = results.nb_labels;
                out.gt_root_dir        = results.gt_root_dir;

                im_gts = {};

                for k=1:length(out.scene_names)
                    scene_name = out.scene_names{k};
                    im_gts{k} = load_ground_truth(out.gt_root_dir, scene_name);
                end

                count = count + 1;
            end

            for k=1:length(out.scene_names)
                scene_name = out.scene_names{k};
                disp(sprintf('      + %s', scene_name));

                for l=1:length(out.seg_names)
                    seg_name = out.seg_names{l};

                    for m=1:length(out.beta_range)
                        beta = out.beta_range(m);

                        for n=1:length(out.gamma_range)
                            gamma = out.gamma_range(n);

                            seg_fn = sprintf('%s%s%s_beta=%f_gamma=%f%s%s_%s_%s_seg.png', my_dirs{j}, filesep, seg_mode, beta, gamma, filesep, seg_mode, scene_name, seg_name);

                            im_seg = uint8(imread(seg_fn));
                            [accuracy,f_measure,~,~] = compare_segmentations(im_seg, im_gts{k}, out.nb_labels);
                            out.accuracy(i,j,k,l,m,n) = accuracy;
                            out.f_measure(i,j,k,l,m,n) = f_measure;
                        end
                    end
                end

                acc = out.accuracy(i,j,k,1,:,:);
                fm = max(out.f_measure(i,j,k,1,:,:));
                best_acc = max(acc(:));
                best_fm = max(fm(:));
                disp(sprintf('     + j=%d | acc=%f, fm=%f', j, best_acc, best_fm));
                m_acc = [m_acc,best_acc];
                m_fm = [m_fm,best_fm];
            end
        end

        disp(sprintf('* mean acc=%f, mean fm=%f', mean(m_acc), mean(m_fm)));

%         acc = mean(out.accuracy,2);
%         fm = mean(out.f_measure,2);
%         for k=1:length(out.scene_names)
%             scene_name = out.scene_names{k};
%             acc = acc(i,1,k,1,:,:);
%             best_acc = max(acc(:));
%             fm = fm(i,1,k,1,:,:);
%             best_fm = max(fm(:));
%             disp(sprintf('* scene %s | best_accuracy=%f, best_f-measure=%f', scene_name, best_acc, best_fm));
%         end

        for j=(length(my_dirs)+1):max_nb_realizations
            out.accuracy(i,j,:,:,:,:) = out.accuracy(i,1,:,:,:,:);
            out.f_measure(i,j,:,:,:,:) = out.f_measure(i,1,:,:,:,:);
        end
    end
end
