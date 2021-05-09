function run_toy_example_eval()
    % Clear all variables and close all windows
    clear all;
    close all;

    % Settings / parameters
    results_dir     = ['..' filesep '..' filesep 'results_toy_example']; % results directory
    results_fn      = [results_dir filesep 'all_scores.mat'];            % results filename
    src_fn          = [results_dir filesep 'im_src.png'];                % data filename
    figures_dir     = ['..' filesep '..' filesep 'figures_toy_example']; % figures directory
    line_thickness  = 2;
    font_size       = 14;

    % We load input image
    im_src = im2double(imread(src_fn));

    % We load ground truth
    im_gt = uint8(im_src>0.5)+1;

    % We load results
    results = load(results_fn);

    % We average scores over noise realizations
    fp_acc      = mean(results.fp_acc,2);
    fp_fm       = mean(results.fp_fm,2);
    coseg_m_acc = mean(results.coseg_m_acc,2);
    coseg_m_fm  = mean(results.coseg_m_fm,2);
    coseg_n_acc = mean(results.coseg_n_acc,2);
    coseg_n_fm  = mean(results.coseg_n_fm,2);

    % We compute best scores and save best segmentations
    best_fp_acc      = double(zeros(size(fp_acc,1),size(fp_acc,3)));
    best_fp_fm       = double(zeros(size(fp_acc,1),size(fp_acc,3)));
    best_coseg_m_acc = double(zeros(size(fp_acc,1),size(fp_acc,3)));
    best_coseg_m_fm  = double(zeros(size(fp_acc,1),size(fp_acc,3)));
    best_coseg_n_acc = double(zeros(size(fp_acc,1),size(fp_acc,3)));
    best_coseg_n_fm  = double(zeros(size(fp_acc,1),size(fp_acc,3)));

    for i=1:size(fp_acc,1)
        disp(sprintf('+ noise level %f', results.noise_levels(i)));

        for k=1:size(fp_acc,3)
            ndi = results.nb_degraded_images_range(k);
            disp(sprintf('  + %d degraded images', ndi));

            fp_acc2 = reshape(fp_acc(i,1,k,:,1),length(results.beta_range),1);
            [best_fp_acc(i,k),argmax] = max(fp_acc2);
            beta_acc = results.beta_range(argmax);
            im_seg = imread([results_dir filesep sprintf('im_seg_fp_%d_%d_%d_%d_%d.png',i,1,k,argmax,1)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_fp_acc_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            %-------------

            fp_fm2  = reshape(fp_fm(i,1,k,:,1),length(results.beta_range),1);
            [best_fp_fm(i,k),argmax] = max(fp_fm2);
            beta_fm = results.beta_range(argmax);
            im_seg = imread([results_dir filesep sprintf('im_seg_fp_%d_%d_%d_%d_%d.png',i,1,k,argmax,1)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_fp_fm_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            disp(sprintf('    + fp | acc=%f (beta=%f,gamma=0.0), fm=%f (beta=%f,gamma=0.0)', best_fp_acc(i,k), beta_acc, best_fp_fm(i,k), beta_fm));

            %--------------------------------------------------------------

            coseg_m_acc2 = reshape(coseg_m_acc(i,1,k,:,:),length(results.beta_range),length(results.gamma_range));
            [best_coseg_m_acc(i,k),argmax] = max(coseg_m_acc2(:));
            [argmax1,argmax2] = ind2sub(size(coseg_m_acc2),argmax);
            beta_acc = results.beta_range(argmax1);
            gamma_acc = results.gamma_range(argmax2);
            im_seg = imread([results_dir filesep sprintf('im_seg_coseg_m_%d_%d_%d_%d_%d.png',i,1,k,argmax1,argmax2)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_coseg_m_acc_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            %-------------
            coseg_m_fm2  = reshape(coseg_m_fm(i,1,k,:,:),length(results.beta_range),length(results.gamma_range));
            [best_coseg_m_fm(i,k),argmax] = max(coseg_m_fm2(:));
            [argmax1,argmax2] = ind2sub(size(coseg_m_fm2),argmax);
            beta_fm = results.beta_range(argmax1);
            gamma_fm = results.gamma_range(argmax2);
            im_seg = imread([results_dir filesep sprintf('im_seg_coseg_m_%d_%d_%d_%d_%d.png',i,1,k,argmax1,argmax2)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_coseg_m_fm_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            disp(sprintf('    + coseg-m | acc=%f (beta=%f,gamma=%f), fm=%f (beta=%f,gamma=%f)', best_coseg_m_acc(i,k), beta_acc, gamma_acc, best_coseg_m_fm(i,k), beta_fm, gamma_fm));

            %--------------------------------------------------------------

            coseg_n_acc2 = reshape(coseg_n_acc(i,1,k,:,:),length(results.beta_range),length(results.gamma_range));
            [best_coseg_n_acc(i,k),argmax] = max(coseg_n_acc2(:));
            [argmax1,argmax2] = ind2sub(size(coseg_n_acc2),argmax);
            beta_acc = results.beta_range(argmax1);
            gamma_acc = results.gamma_range(argmax2);
            im_seg = imread([results_dir filesep sprintf('im_seg_coseg_n_%d_%d_%d_%d_%d.png',i,1,k,argmax1,argmax2)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_coseg_n_acc_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            %-------------

            coseg_n_fm2  = reshape(coseg_n_fm(i,1,k,:,:),length(results.beta_range),length(results.gamma_range));
            [best_coseg_n_fm(i,k),argmax] = max(coseg_n_fm2(:));
            [argmax1,argmax2] = ind2sub(size(coseg_n_fm2),argmax);
            beta_fm = results.beta_range(argmax1);
            gamma_fm = results.gamma_range(argmax2);
            im_seg = imread([results_dir filesep sprintf('im_seg_coseg_n_%d_%d_%d_%d_%d.png',i,1,k,argmax1,argmax2)]);
            imwrite(blend_images(im_src, get_diff_segmentation(im_seg, im_gt), 0.0), [figures_dir filesep sprintf('toy_example_seg_coseg_n_fm_k=%d_sigma=%f.png', ndi, results.noise_levels(i))]);

            disp(sprintf('    + coseg-n | acc=%f (beta=%f,gamma=%f), fm=%f (beta=%f,gamma=%f)', best_coseg_n_acc(i,k), beta_acc, gamma_acc, best_coseg_n_fm(i,k), beta_fm, gamma_fm));
        end
    end

    % We plot segmentation performance against number of degraded images for two noise levels
    sigma1 = 0.05;
    sigma2 = 0.5;
    index1 = find(results.noise_levels==sigma1);
    index2 = find(results.noise_levels==sigma2);

    h = figure;
    hold on;
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_m_acc(index1,:), 'LineStyle', '-', 'Color', [1,0,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_n_acc(index1,:), 'LineStyle', '-', 'Color', [0,0,1]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_fp_acc(index1,:), 'LineStyle', '-', 'Color', [0,1,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_m_acc(index2,:), 'LineStyle', '--', 'Color', [1,0,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_n_acc(index2,:), 'LineStyle', '--', 'Color', [0,0,1]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_fp_acc(index2,:), 'LineStyle', '--', 'Color', [0,1,0]);
    xlabel('Ratio of corrupted images \rho');
    ylabel('Mean ACC (%)');
    grid;
    set(gca, 'GridColor', [0,0,0]);
    fn = [figures_dir filesep 'toy_example_varying_rho_acc.png'];
    legend({sprintf('MLJS-M (\\sigma=%.2f)',sigma1),sprintf('MLJS-N (\\sigma=%.2f)',sigma1),sprintf('FP (\\sigma=%.2f)',sigma1),sprintf('MLJS-M (\\sigma=%.2f)',sigma2),sprintf('MLJS-N (\\sigma=%.2f)',sigma2),sprintf('FP (\\sigma=%.2f)',sigma2)}, 'Location', 'southwest');
    set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
    set(gca, 'linewidth', line_thickness);
    set(gca, 'FontSize', font_size);
    saveas(h, fn);
    close(h);
    system(sprintf('mogrify -trim %s', fn));

    %-------------------

    h = figure;
    hold on;
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_m_fm(index1,:), 'LineStyle', '-', 'Color', [1,0,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_n_fm(index1,:), 'LineStyle', '-', 'Color', [0,0,1]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_fp_fm(index1,:), 'LineStyle', '-', 'Color', [0,1,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_m_fm(index2,:), 'LineStyle', '--', 'Color', [1,0,0]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_coseg_n_fm(index2,:), 'LineStyle', '--', 'Color', [0,0,1]);
    plot(results.nb_degraded_images_range/results.nb_degraded_images_range(end), best_fp_fm(index2,:), 'LineStyle', '--', 'Color', [0,1,0]);
    xlabel('Ratio of corrupted images \rho');
    ylabel('Mean FM (%)');
    grid;
    set(gca, 'GridColor', [0,0,0]);
    fn = [figures_dir filesep 'toy_example_varying_rho_fm.png'];
    legend({sprintf('MLJS-M (\\sigma=%.2f)',sigma1),sprintf('MLJS-N (\\sigma=%.2f)',sigma1),sprintf('FP (\\sigma=%.2f)',sigma1),sprintf('MLJS-M (\\sigma=%.2f)',sigma2),sprintf('MLJS-N (\\sigma=%.2f)',sigma2),sprintf('FP (\\sigma=%.2f)',sigma2)}, 'Location', 'southwest');
    set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
    set(gca, 'linewidth', line_thickness);
    set(gca, 'FontSize', font_size);
    saveas(h, fn);
    close(h);
    system(sprintf('mogrify -trim %s', fn));

    % We plot segmentation performance against noise levels for two number of degraded images
    rho1     = 1/3;
    rho2     = 2/3;
    str1     = '1/3';
    str2     = '2/3';
    k1       = round(rho1*results.nb_degraded_images_range(end));
    k2       = round(rho2*results.nb_degraded_images_range(end));
    index1   = find(results.nb_degraded_images_range==k1);
    index2   = find(results.nb_degraded_images_range==k2);

    h = figure;
    hold on;
    plot(results.noise_levels, best_coseg_m_acc(:,index1), 'LineStyle', '-', 'Color', [1,0,0]);
    plot(results.noise_levels, best_coseg_n_acc(:,index1), 'LineStyle', '-', 'Color', [0,0,1]);
    plot(results.noise_levels, best_fp_acc(:,index1), 'LineStyle', '-', 'Color', [0,1,0]);
    plot(results.noise_levels, best_coseg_m_acc(:,index2), 'LineStyle', '--', 'Color', [1,0,0]);
    plot(results.noise_levels, best_coseg_n_acc(:,index2), 'LineStyle', '--', 'Color', [0,0,1]);
    plot(results.noise_levels, best_fp_acc(:,index2), 'LineStyle', '--', 'Color', [0,1,0]);
    xlabel('Noise level \sigma');
    ylabel('Mean ACC (%)');
    grid;
    set(gca, 'GridColor', [0,0,0]);
    fn = [figures_dir filesep 'toy_example_varying_sigma_acc.png'];
    legend({sprintf('MLJS-M (\\rho=%s)',str1),sprintf('MLJS-N (\\rho=%s)',str1),sprintf('FP (\\rho=%s)',str1),sprintf('MLJS-M (\\rho=%s)',str2),sprintf('MLJS-N (\\rho=%s)',str2),sprintf('FP (\\rho=%s)',str2)}, 'Location', 'southwest');
    set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
    set(gca, 'linewidth', line_thickness);
    set(gca, 'FontSize', font_size);
    saveas(h, fn);
    close(h);
    system(sprintf('mogrify -trim %s', fn));

    %-------------------

    h = figure;
    hold on;
    plot(results.noise_levels, best_coseg_m_fm(:,index1), 'LineStyle', '-', 'Color', [1,0,0]);
    plot(results.noise_levels, best_coseg_n_fm(:,index1), 'LineStyle', '-', 'Color', [0,0,1]);
    plot(results.noise_levels, best_fp_fm(:,index1), 'LineStyle', '-', 'Color', [0,1,0]);
    plot(results.noise_levels, best_coseg_m_fm(:,index2), 'LineStyle', '--', 'Color', [1,0,0]);
    plot(results.noise_levels, best_coseg_n_fm(:,index2), 'LineStyle', '--', 'Color', [0,0,1]);
    plot(results.noise_levels, best_fp_fm(:,index2), 'LineStyle', '--', 'Color', [0,1,0]);
    xlabel('Noise level \sigma');
    ylabel('Mean FM (%)');
    grid;
    set(gca, 'GridColor', [0,0,0]);
    fn = [figures_dir filesep 'toy_example_varying_sigma_fm.png'];
    legend({sprintf('MLJS-M (\\rho=%s)',str1),sprintf('MLJS-N (\\rho=%s)',str1),sprintf('FP (\\rho=%s)',str1),sprintf('MLJS-M (\\rho=%s)',str2),sprintf('MLJS-N (\\rho=%s)',str2),sprintf('FP (\\rho=%s)',str2)}, 'Location', 'southwest');
    set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
    set(gca, 'linewidth', line_thickness);
    set(gca, 'FontSize', font_size);
    saveas(h, fn);
    close(h);
    system(sprintf('mogrify -trim %s', fn));

    % We plot segmentation performance against regularization parameters
    sigmas    = [0.25,0.5];
    nb_ticks  = 6;
    rho       = 0.5;
    ndi       = round(rho*results.nb_degraded_images_range(end));
    ndi_idx   = find(results.nb_degraded_images_range==ndi);

    for k=1:length(sigmas)
        sigma = sigmas(k);
        sigma_idx = find(results.noise_levels==sigma);

        %-------------

        h = figure;
        hold on;
        d = reshape(fp_acc(sigma_idx,1,ndi_idx,:,1), length(results.beta_range), 1);
        plot(1:length(results.beta_range),d);
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'XTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'XTickLabel', beta_labels);
        xlabel('Weighting parameter \beta');
        xlim([1,length(results.beta_range)]);
        ylabel('ACC (%)');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_fp_sigma=%.2f_acc.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);

        %-------------

        h = figure;
        hold on;
        d = reshape(fp_fm(sigma_idx,1,ndi_idx,:,1), length(results.beta_range), 1);
        plot(1:length(results.beta_range),d);
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'XTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'XTickLabel', beta_labels);
        xlabel('Weighting parameter \beta');
        xlim([1,length(results.beta_range)]);
        ylabel('FM (%)');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_fp_sigma=%.2f_fm.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);

        %------------------------------------------------------------------

        h = figure;
        hold on;
        d = reshape(coseg_m_acc(sigma_idx,1,ndi_idx,:,:), length(results.beta_range), length(results.gamma_range));
        imagesc(d);
        set(gca,'YDir','normal');
        gamma_ticks1 = round(linspace(1, length(results.gamma_range), nb_ticks));
        gamma_ticks2 = [0,results.gamma_min_exp:results.gamma_max_exp];
        set(gca, 'XTick', gamma_ticks1);
        gamma_labels = [num2str(0);cellstr(num2str(gamma_ticks2(gamma_ticks1(2:end))', sprintf('%.1f^{%%d}', results.gamma_cr)))];
        set(gca, 'XTickLabel', gamma_labels);
        xlabel('Weighting parameter \gamma');
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'YTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'YTickLabel', beta_labels);
        ylabel('Weighting parameter \beta');
        axis equal tight;
        colorbar;
        colormap('gray');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_coseg_m_sigma=%.2f_acc.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);

        %-----------------

        h = figure;
        hold on;
        d = reshape(coseg_m_fm(sigma_idx,1,ndi_idx,:,:), length(results.beta_range), length(results.gamma_range));
        imagesc(d);
        set(gca,'YDir','normal');
        gamma_ticks1 = round(linspace(1, length(results.gamma_range), nb_ticks));
        gamma_ticks2 = [0,results.gamma_min_exp:results.gamma_max_exp];
        set(gca, 'XTick', gamma_ticks1);
        gamma_labels = [num2str(0);cellstr(num2str(gamma_ticks2(gamma_ticks1(2:end))', sprintf('%.1f^{%%d}', results.gamma_cr)))];
        set(gca, 'XTickLabel', gamma_labels);
        xlabel('Weighting parameter \gamma');
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'YTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'YTickLabel', beta_labels);
        ylabel('Weighting parameter \beta');
        axis equal tight;
        colorbar;
        colormap('gray');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_coseg_m_sigma=%.2f_fm.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);

        %------------------------------------------------------------------

        h = figure;
        hold on;
        d = reshape(coseg_n_acc(sigma_idx,1,ndi_idx,:,:), length(results.beta_range), length(results.gamma_range));
        imagesc(d);
        set(gca,'YDir','normal');
        gamma_ticks1 = round(linspace(1, length(results.gamma_range), nb_ticks));
        gamma_ticks2 = [0,results.gamma_min_exp:results.gamma_max_exp];
        set(gca, 'XTick', gamma_ticks1);
        gamma_labels = [num2str(0);cellstr(num2str(gamma_ticks2(gamma_ticks1(2:end))', sprintf('%.1f^{%%d}', results.gamma_cr)))];
        set(gca, 'XTickLabel', gamma_labels);
        xlabel('Weighting parameter \gamma');
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'YTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'YTickLabel', beta_labels);
        ylabel('Weighting parameter \beta');
        axis equal tight;
        colorbar;
        colormap('gray');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_coseg_n_sigma=%.2f_acc.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);

        %-----------------

        h = figure;
        hold on;
        d = reshape(coseg_n_fm(sigma_idx,1,ndi_idx,:,:), length(results.beta_range), length(results.gamma_range));
        imagesc(d);
        set(gca,'YDir','normal');
        gamma_ticks1 = round(linspace(1, length(results.gamma_range), nb_ticks));
        gamma_ticks2 = [0,results.gamma_min_exp:results.gamma_max_exp];
        set(gca, 'XTick', gamma_ticks1);
        gamma_labels = [num2str(0);cellstr(num2str(gamma_ticks2(gamma_ticks1(2:end))', sprintf('%.1f^{%%d}', results.gamma_cr)))];
        set(gca, 'XTickLabel', gamma_labels);
        xlabel('Weighting parameter \gamma');
        beta_ticks1 = round(linspace(1, length(results.beta_range), nb_ticks));
        beta_ticks2 = [0,results.beta_min_exp:results.beta_max_exp];
        set(gca, 'YTick', beta_ticks1);
        beta_labels = [num2str(0);cellstr(num2str(beta_ticks2(beta_ticks1(2:end))', sprintf('%.1f^{%%d}', results.beta_cr)))];
        set(gca, 'YTickLabel', beta_labels);
        ylabel('Weighting parameter \beta');
        axis equal tight;
        colorbar;
        colormap('gray');
        grid;
        set(findall(gca, 'Type', 'Line'), 'LineWidth', line_thickness);
        set(gca, 'linewidth', line_thickness);
        set(gca, 'FontSize', font_size);
        fn = [figures_dir filesep sprintf('toy_example_sensitivity_coseg_n_sigma=%.2f_fm.png', sigma)];
        saveas(gcf, fn);
        system(sprintf('mogrify -trim %s', fn));
        close(h);
    end
end