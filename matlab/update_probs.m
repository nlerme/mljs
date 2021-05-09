% Function updating probabilities
function probs = update_probs( scores, thetas )
    image_sy  = size(scores, 1);
    image_sx  = size(scores, 2);
    nb_images = size(scores, 3);
    nb_labels = size(scores, 4);
    probs     = scores;

    for i=1:nb_images
        for y=1:image_sy
            for x=1:image_sx
                for j=1:nb_labels
                    e = thetas(i,j,1)*scores(y,x,i,j)+thetas(i,j,2);
                    probs(y,x,i,j) = 1/(1+exp(e));
                end
            end
        end
    end
end