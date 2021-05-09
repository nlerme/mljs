function [im_seg,E,D,S,t] = run_seg( data_costs, probs, connectivity, beta, nb_labels, sigmasI, resolution )
    % Variables
    image_sy   = size(data_costs,1);
    image_sx   = size(data_costs,2);
    nb_images  = size(data_costs,3);
    image_size = (image_sx*image_sy);
    nb_sites   = image_size;

    % Allocation
    h = GCO_Create(nb_sites, nb_labels);

    % Data costs assignment
    %disp('+ data costs assignment');
    dc = double(zeros(nb_labels, nb_sites));

    for x=0:(image_sx-1)
        for y=0:(image_sy-1)
            offset = x+y*image_sx+1;
            for l=1:nb_labels
                dc(l,offset) = sum(data_costs(y+1,x+1,:,l));
            end
        end
    end

    GCO_SetDataCost(h, dc);

    % Smoothness costs assignment
    %disp('+ smoothness costs assignment');
    sc = double(~diag(ones(1,nb_labels)));
    GCO_SetSmoothCost(h, sc);

    % Neighbors assignment
    %disp('+ neighbors assignment');

    if connectivity==0
        nb_non_null_values = 2*image_size;
    else
        nb_non_null_values = 4*image_size;
    end

    offsets1 = zeros(1, nb_non_null_values);
    offsets2 = zeros(1, nb_non_null_values);
    costs    = double(zeros(1, nb_non_null_values));
    count    = 1;

    for x1=0:(image_sx-1)
        for y1=0:(image_sy-1)
            for x2=max(x1-1,0):min(x1+1,image_sx-1)
                for y2=max(y1-1,0):min(y1+1,image_sy-1)
                    offset1 = x1+y1*image_sx+1;
                    offset2 = x2+y2*image_sx+1;

                    if offset1>=offset2 || (connectivity==0 && (abs(x1-x2)+abs(y1-y2))>1)
                        continue;
                    end

                    cost = 0.0;
                    for i=1:nb_images
                        a = probs(y1+1,x1+1,i,:);
                        b = probs(y2+1,x2+1,i,:);
                        cost = cost + exp(-sum((a-b).^2)/(2.0*sigmasI(i)^2));
                    end
                    cost = cost * beta * (1/sqrt(resolution(1)^2*(x1-x2)^2 + resolution(2)^2*(y1-y2)^2));

%                     a               = probs0(y1+1,x1+1,1,:);
%                     b               = probs0(y2+1,x2+1,1,:);
%                     cost            = beta*1/sqrt(resolution(1)^2*(x1-x2)^2 + resolution(2)^2*(y1-y2)^2);
%                     cost            = cost*exp(-sum((a-b).^2)/(2*sigmaI^2));

                    offsets1(count) = offset1;
                    offsets2(count) = offset2;
                    costs(count)    = cost;

                    count = count + 1;
                end
            end
        end
    end

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
    im_seg = uint8(GCO_GetLabeling(h));
    im_seg = reshape(im_seg, image_sx, image_sy)';

    % Deallocation
    GCO_Delete(h);
end