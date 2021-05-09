% Function returning estimates of constrast parameters used in intra-images smoothness terms
function sigmasI = get_sigmasI_estimates( probs, connectivity )
    image_sy  = size(probs, 1);
    image_sx  = size(probs, 2);
    nb_images = size(probs, 3);
    nb_labels = size(probs, 4);
    sigmasI   = double(zeros(1,nb_images));

    for s=1:nb_images
        count = 0;

        for x1=0:(image_sx-1)
            for y1=0:(image_sy-1)
                for x2=max(x1-1,0):min(x1+1,image_sx-1)
                    for y2=max(y1-1,0):min(y1+1,image_sy-1)
                        offset1 = x1+y1*image_sx+1;
                        offset2 = x2+y2*image_sx+1;

                        if offset1>=offset2 || (connectivity==0 && (abs(x1-x2)+abs(y1-y2))>1)
                            continue;
                        end

                        a = reshape(probs(y1+1,x1+1,s,:),1,nb_labels);
                        b = reshape(probs(y2+1,x2+1,s,:),1,nb_labels);
                        sigmasI(s) = sigmasI(s) + norm(a-b)^2;
                        count = count + 1;
                    end
                end
            end
        end

        sigmasI(s) = sqrt(sigmasI(s)/(count-1));
        %disp(sprintf('  + sigmasI(%d) = %f', s, sigmasI(s)));
    end
end