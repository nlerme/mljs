% Function returning estimates of constrast parameters used in inter-images smoothness terms
function sigmasC = get_sigmasC_estimates( probs )
    image_size = size(probs, 1)*size(probs, 2);
    nb_images  = size(probs, 3);
    nb_labels  = size(probs, 4);
    sigmasC    = double(zeros(nb_images));

    for s1=1:nb_images
        for s2=1:nb_images
            im1 = reshape(probs(:,:,s1,:), 1, image_size*nb_labels);
            im2 = reshape(probs(:,:,s2,:), 1, image_size*nb_labels);
            sigmasC(s1,s2) = sqrt(sum((im1-im2).^2)/(image_size-1));
            %if s1<s2
            %    disp(sprintf('  + sigmasC(%d,%d) = %f', s1, s2, sigmasC(s1,s2)));
            %end
        end
    end
end