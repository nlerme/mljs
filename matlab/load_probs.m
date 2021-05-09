% Function loading probabilities
function all_probs = load_probs( probs_dir, dx_names, scene_name, nb_labels )
    nb_images = length(dx_names);

    for i=1:nb_images
        %disp(sprintf('+ %s', dx_names{i}));

        for j=1:nb_labels
            %im_tmp = double(dlmread(sprintf('prob_maps/normal_data/%s/%s_%02d', dx_names{i}, scene_name, j)));
            %im_tmp = im2double(imread(sprintf('prob_maps/normal_data/%s/%s_%02d.tif', dx_names{i}, scene_name, j)));
            fn = [probs_dir filesep dx_names{i} filesep scene_name filesep 'Score_SVM_' num2str(j) '.mat'];
            load(fn, 'probs');

            if j==1 && i==1
                image_sy = size(probs,1);
                image_sx = size(probs,2);
                all_probs = double(zeros(image_sy,image_sx,nb_images,nb_labels));
            end

            all_probs(:,:,i,j) = probs;
            clear probs;
            %disp(sprintf('  + label %d | min=%f, max=%f, mean=%f, std=%f', j, min(im_tmp(:)), max(im_tmp(:)), mean(im_tmp(:)), std(im_tmp(:))));
        end
    end
end