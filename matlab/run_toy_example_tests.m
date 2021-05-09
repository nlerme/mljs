function run_toy_example_tests()
    % Clear all variables and close all windows
    clear all;
    close all;

    % Settings / parameters
    results_dir     = ['..' filesep '..' filesep 'results4'];      % results directory
    results_fn      = [results_dir filesep 'all_scores.mat'];      % results filename
    data_dir        = ['..' filesep '..' filesep 'data'];          % data directory
    mu              = [0.45,0.55];                                 % foreground/background intensities
    nb_labels       = 2;                                           % number of labels
    nb_images       = 8;                                           % number of images
    connectivity1   = 1;                                           % 8-neighbors spatial connectivity
    resolution      = [1,1];                                       % image resolution (x,y)
    nb_realizations = 1;                                          % number of noise realizations
    noise_levels    = linspace(0,1,21);                            % standard deviations of corrupted images
    beta_cr         = 2;                                           % common ratio of beta coefficient
    beta_min_exp    = -13;                                         % minimum exponent of beta coefficient
    beta_max_exp    = 0;                                           % maximum exponent of beta coefficient
    beta_range      = [0,beta_cr.^(beta_min_exp:beta_max_exp)];    % range of beta coefficient
    gamma_cr        = 2.5;                                         % common ratio of gamma coefficient
    gamma_min_exp   = -13;                                         % minimum exponent of gamma coefficient
    gamma_max_exp   = 0;                                           % maximum exponent of gamma coefficient
    gamma_range     = [0,gamma_cr.^(gamma_min_exp:gamma_max_exp)]; % range of gamma coefficient
    save_results    = 0;                                           % save results into a MATLAB file

    % We create source, ground truth and degraded images (test pattern)
    im_gt            = uint8(imread([data_dir filesep 'toy_example.png'])>0)+1;
    image_size       = size(im_gt,1);
    im_src           = double(zeros(image_size));
    im_src(im_gt==2) = mu(2);
    im_src(im_gt==1) = mu(1);
    im_src2 = repmat(im_src,1,1,nb_images) + randn(image_size,image_size,nb_images)*0.0001;
    if save_results
        imwrite(im_src, [results_dir filesep 'im_src.png']);
        imwrite(blend_images(im_src,im_gt,0.7), [results_dir filesep 'im_gt.png']);
    end

    % We generate degraded images
    nb_noise_levels = length(noise_levels);
    im_degraded     = double(zeros(image_size,image_size,nb_images,nb_noise_levels,nb_realizations));

    for i=1:nb_noise_levels
        sigma = noise_levels(i);
        for j=1:nb_realizations
            for k=1:nb_images
                im_tmp1 = im_src+randn(image_size)*sigma;
                %pause(2.0);
                if j==1 && k==1
                    im_tmp2 = uint8(255*(im_tmp1-min(im_tmp1(:)))./(max(im_tmp1(:))-min(im_tmp1(:))));
                    %figure, imshow(im_tmp1,[]);
                    if save_results
                        imwrite(im_tmp2, [results_dir filesep sprintf('im_noise_sigma=%.2f.png',sigma)]);
                    end
                end
                im_degraded(:,:,k,i,j) = im_tmp1;
            end
        end
    end

    % We create empty arrays for storing scores
    nb_degraded_images_range = 0:nb_images;
    fp_acc                   = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));
    fp_fm                    = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));
    coseg_m_acc              = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));
    coseg_m_fm               = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));
    coseg_n_acc              = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));
    coseg_n_fm               = double(zeros(nb_noise_levels,nb_realizations,length(nb_degraded_images_range),length(beta_range),length(gamma_range)));

    % We loop over noise levels
    for i=1:nb_noise_levels
        sigma = noise_levels(i);
        disp(sprintf('+ noise level sigma=%f', sigma));

        % We loop over noise realizations
        for j=1:nb_realizations
            disp(sprintf('  + noise realization %d', j));

            % We loop over the number of degraded images
            for k=1:length(nb_degraded_images_range)
                nb_degraded_images = nb_degraded_images_range(k);
                disp(sprintf('    + %d degraded images', nb_degraded_images));
                im_src3 = im_src2;

                if nb_degraded_images>0 && sigma>0
                    im_src3(:,:,1:nb_degraded_images) = im_degraded(:,:,1:nb_degraded_images,i,j);
                end

                % We loop over beta coefficient values
                for l=1:length(beta_range)
                    beta = beta_range(l);
                    disp(sprintf('      + beta=%f', beta));

                    % We loop over gamma coefficient values
                    for m=1:length(gamma_range)
                        gamma = gamma_range(m);
                        disp(sprintf('        + gamma=%f', gamma));

                        % We run FP segmentation
                        sigmasI = get_sigmasI_estimates(im_src3, connectivity1);
                        [im_seg,E,D,S,t] = run_seg_g(im_src3, connectivity1, beta, nb_labels, 100000*ones(size(sigmasI)), mu, resolution, 0);
                        [fp_acc(i,j,k,l,m),fp_fm(i,j,k,l,m),~,~] = compare_segmentations(im_seg, im_gt, nb_labels);
                        fn = [results_dir filesep sprintf('im_seg_fp_%d_%d_%d_%d_%d.png', i, j, k, l, m)];
                        if save_results
                            imwrite(im_seg, fn);
                        end
                        disp(sprintf('          + fp segmentation | time=%f, acc=%f, fm=%f', t, fp_acc(i,j,k,l,m), fp_fm(i,j,k,l,m)));
                        %figure, imshow(blend_images(zeros(image_size), im_seg, 0.0),[]);

                        % We run matched cosegmentation
                        connectivity2 = 0;
                        sigmasI = get_sigmasI_estimates(im_src3, connectivity1);
                        sigmasC = get_sigmasC_estimates(im_src3);
                        [im_segs,E,D,S,t] = run_coseg_g(im_src3, connectivity1, connectivity2, beta*ones(1,nb_images), gamma*(1-eye(nb_images)), nb_labels, 100000*ones(size(sigmasI)), sigmasC, mu, resolution, 0);
                        im_seg = im_segs(:,:,nb_images+1);
                        [coseg_m_acc(i,j,k,l,m),coseg_m_fm(i,j,k,l,m),~,~] = compare_segmentations(im_seg, im_gt, nb_labels);
                        fn = [results_dir filesep sprintf('im_seg_coseg_m_%d_%d_%d_%d_%d.png', i, j, k, l, m)];
                        if save_results
                            imwrite(im_seg, fn);
                        end
                        disp(sprintf('          + matched cosegmentation | time=%f, acc=%f, fm=%f', t, coseg_m_acc(i,j,k,l,m), coseg_m_fm(i,j,k,l,m)));
                        %figure, imshow(blend_images(zeros(image_size), im_seg, 0.0),[]);

                        % We run nearby cosegmentation
                        connectivity2 = 2;
                        sigmasI = get_sigmasI_estimates(im_src3, connectivity1);
                        sigmasC = get_sigmasC_estimates(im_src3);
                        [im_segs,E,D,S,t] = run_coseg_g(im_src3, connectivity1, connectivity2, beta*ones(1,nb_images), gamma*(1-eye(nb_images)), nb_labels, 100000*ones(size(sigmasI)), sigmasC, mu, resolution, 0);
                        im_seg = im_segs(:,:,nb_images+1);
                        [coseg_n_acc(i,j,k,l,m),coseg_n_fm(i,j,k,l,m),~,~] = compare_segmentations(im_seg, im_gt, nb_labels);
                        fn = [results_dir filesep sprintf('im_seg_coseg_n_%d_%d_%d_%d_%d.png', i, j, k, l, m)];
                        if save_results
                            imwrite(im_seg, fn);
                        end
                        disp(sprintf('          + nearby cosegmentation | time=%f, acc=%f, fm=%f', t, coseg_n_acc(i,j,k,l,m), coseg_n_fm(i,j,k,l,m)));
                        %figure, imshow(blend_images(zeros(image_size), im_seg, 0.0),[]);
                    end
                end
            end
        end
    end

    % We save results
    if save_results
        save(results_fn, 'nb_labels', 'nb_images', 'nb_realizations', 'noise_levels', 'beta_cr', 'beta_min_exp', 'beta_max_exp', 'beta_range', ...
                         'gamma_cr', 'gamma_min_exp', 'gamma_max_exp', 'gamma_range', 'nb_degraded_images_range', ...
                         'fp_acc', 'fp_fm', 'coseg_m_acc', 'coseg_m_fm', 'coseg_n_acc', 'coseg_n_fm');
    end
end
