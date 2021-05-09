% Function loading resulting scores from SVMs
function scores = load_scores( dx_root_dir, dx_names, scene_name )
    nb_images = length(dx_names);

    for i=1:nb_images
        %disp(sprintf('  + %s', dx_names{i}));
        dx_label_names = get_matching_files([dx_root_dir filesep dx_names{i} filesep scene_name], '.*');
        nb_labels = length(dx_label_names);
        for j=1:nb_labels
            im_tmp = double(dlmread(dx_label_names{j}));
            if j==1 && i==1
                image_sy = size(im_tmp,1);
                image_sx = size(im_tmp,2);
                scores = double(zeros(image_sy,image_sx,nb_images,nb_labels));
            end
            scores(:,:,i,j) = im_tmp;
            %disp(sprintf('    + label %d | min score=%f, max score=%f', j, min(im_tmp(:)), max(im_tmp(:))));
        end
    end
end