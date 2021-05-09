% Function updating data costs
function costs = update_data_costs( probs )
    image_sy  = size(probs, 1);
    image_sx  = size(probs, 2);
    nb_images = size(probs, 3);
    nb_labels = size(probs, 4);
    costs     = probs;

    for i=1:nb_images
        for y=1:image_sy
            for x=1:image_sx
                for j=1:nb_labels
                    costs(y,x,i,j) = -log(0.1+probs(y,x,i,j));
                end
            end
        end
    end
end
