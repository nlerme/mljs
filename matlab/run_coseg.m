function [im_segs,E,D,S,t] = run_coseg( data_costs, probs, connectivity1, connectivity2, betas, gammas, nb_labels, sigmasI, sigmasC, resolution )
    % Variables
    image_sy   = size(data_costs,1);
    image_sx   = size(data_costs,2);
    nb_images  = size(data_costs,3);
    image_size = (image_sx*image_sy);
    nb_sites   = (nb_images+1)*image_size; % nb images + coseg

    % Allocation
    h = GCO_Create(nb_sites, nb_labels);

    % Data costs assignment
    %disp('+ data costs assignment');
    dc = double(zeros(nb_labels, nb_sites));

    for s=0:(nb_images-1)
        for x=0:(image_sx-1)
            for y=0:(image_sy-1)
                offset = x+y*image_sx+s*image_size+1;
                for l=1:nb_labels
                    dc(l, offset) = data_costs(y+1,x+1,s+1,l);
                end
            end
        end
    end

    GCO_SetDataCost(h, dc);

    % Smoothness costs assignment
    %disp('+ smoothness costs assignment');
    sc = double(~diag(ones(1,nb_labels)));
    GCO_SetSmoothCost(h, sc);

    % Intra-layer neighbors assignment
    %disp('+ intra-layer neighbors assignment');
    if connectivity1==0
        nb_non_null_values = 2*image_size*(nb_images-1);
    elseif connectivity1==1
        nb_non_null_values = 4*image_size*(nb_images-1);
    else
        disp('error: unknown connectivity1 value (can be either 0 or 1)');
        return;
    end

    if connectivity2==0
        nb_non_null_values = nb_non_null_values + (nb_images*image_size);
    elseif connectivity2==1
        nb_non_null_values = nb_non_null_values + (3*nb_images*image_size);
    elseif connectivity2==2
        nb_non_null_values = nb_non_null_values + (5*nb_images*image_size);
    else
        disp('error: unknown connectivity2 value (can be either 0, 1 or 2)');
        return;
    end

    offsets1 = zeros(1, nb_non_null_values);
    offsets2 = zeros(1, nb_non_null_values);
    costs    = double(zeros(1, nb_non_null_values));
    count    = 1;

    for s=0:(nb_images-1)
        for x1=0:(image_sx-1)
            for y1=0:(image_sy-1)
                for x2=max(x1-1,0):min(x1+1,image_sx-1)
                    for y2=max(y1-1,0):min(y1+1,image_sy-1)
                        offset1 = x1+y1*image_sx+s*image_size+1;
                        offset2 = x2+y2*image_sx+s*image_size+1;

                        if offset1>=offset2 || (connectivity1==0 && (abs(x1-x2)+abs(y1-y2))>1)
                            continue;
                        end

                        a               = probs(y1+1,x1+1,s+1,:);
                        b               = probs(y2+1,x2+1,s+1,:);
                        cost            = betas(s+1)*(1/sqrt(resolution(1)^2*(x1-x2)^2 + resolution(2)^2*(y1-y2)^2));
                        cost            = cost*exp(-sum((a-b).^2) / (2.0*sigmasI(s+1)^2));
                        offsets1(count) = offset1;
                        offsets2(count) = offset2;
                        costs(count)    = cost;

                        count = count + 1;
                    end
                end
            end
        end
    end

    % Inter-layer neighbors assignment
    %disp('+ inter-layer neighbors assignment');
    costs2 = double(zeros(image_sy,image_sx,nb_images));

    for x=0:(image_sx-1)
        for y=0:(image_sy-1)
            for s1=0:(nb_images-1)
                cost = 0.0;

                for s2=0:(nb_images-1)
                    if s1==s2
                        continue;
                    end

                    a    = probs(y+1,x+1,s1+1,:);
                    b    = probs(y+1,x+1,s2+1,:);
                    cost = cost + gammas(s1+1,s2+1) * exp(-sum((a-b).^2) / (2.0*sigmasC(s1+1,s2+1)^2));
                end

                costs2(y+1,x+1,s1+1) = cost;
            end
        end
    end

    if connectivity2==0
        for x=0:(image_sx-1)
            for y=0:(image_sy-1)
                for s=0:(nb_images-1)
                    offset1 = x+y*image_sx+s*image_size+1;
                    offset2 = x+y*image_sx+nb_images*image_size+1;

                    offsets1(count) = offset1;
                    offsets2(count) = offset2;
                    costs(count)    = costs2(y+1,x+1,s+1);

                    count = count + 1;
                end
            end
        end
    else
        for x1=0:(image_sx-1)
            for y1=0:(image_sy-1)
                for x2=max(x1-1,0):min(x1+1,image_sx-1)
                    for y2=max(y1-1,0):min(y1+1,image_sy-1)
                        if (connectivity2==1 && (abs(x1-x2)+abs(y1-y2))>1)
                            continue;
                        end

                        for s=0:(nb_images-1)
                            offset1 = x2+y2*image_sx+s*image_size+1;
                            offset2 = x1+y1*image_sx+nb_images*image_size+1;

                            offsets1(count) = offset1;
                            offsets2(count) = offset2;
                            costs(count)    = costs2(y2+1,x2+1,s+1) * (1/sqrt(1+resolution(1)^2*(x1-x2)^2 + resolution(2)^2*(y1-y2)^2));

                            count = count + 1;
                        end
                    end
                end
            end
        end
    end
    %disp('mrf built!');

    index    = find(offsets1>0, 1, 'last');
    offsets1 = offsets1(1:index);
    offsets2 = offsets2(1:index);
    costs    = costs(1:index);
    n        = sparse(offsets1, offsets2, costs, nb_sites, nb_sites);
    GCO_SetNeighbors(h, n);

    % Optimization
    %disp('+ optimization');
    GCO_SetVerbosity(h, 2);
    t = tic;
    GCO_Expansion(h, 100);
    t = toc(t);

    [E D S] = GCO_ComputeEnergy(h);
    %disp(sprintf('  + data energy = %f', D));
    %disp(sprintf('  + smoothness energy = %f', S));
    %disp(sprintf('  + total energy = %f', E));

    % Labelings separation
    res = GCO_GetLabeling(h);
    im_segs = uint8(zeros(image_sy, image_sx, nb_images+1));

    for s=0:nb_images
        im_tmp1          = res((s*image_size+1):((s+1)*image_size));
        im_tmp2          = reshape(im_tmp1, image_sx, image_sy)';
        im_segs(:,:,s+1) = im_tmp2;
    end

    % Deallocation
    GCO_Delete(h);
end