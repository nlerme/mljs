% Function loading parameters of sigmoids
function thetas = load_sigmoids_params( dx_names, params_fn, nb_images, nb_labels )
    thetas_tab = dlmread(params_fn);
    thetas = double(zeros(nb_images,nb_labels,2));
    for i=1:nb_images
        %disp(sprintf('  + %s', dx_names{i}));
        for j=1:nb_labels
            thetas(i,j,1) = thetas_tab(i,2*(j-1)+1);
            thetas(i,j,2) = thetas_tab(i,2*(j-1)+2);
            %disp(sprintf('    + label %d | theta=(%f,%f)', j, thetas(i,j,1), thetas(i,j,2)));
        end
    end
end