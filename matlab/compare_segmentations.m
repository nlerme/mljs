function [acc,fm,asasd,msasd] = compare_segmentations( im_seg1, im_seg2, nb_classes )
    % Returns comparison measures between two multi-labels segmentations.
    % 
    % Input arguments:
    %   - im_seg1 : first segmentation
    %   - im_seg2 : second segmentation (e.g. ground truth)
    % 
    % Output arguments:
    %   - acc   : accuracy averaged over classes (in [0,100])
    %   - fm    : F-measure (in [0,100])
    %   - asasd : average symmetric absolute surface distance (in R^+) | TODO
    %   - msasd : maximum symmetric absolute surface distance (in R^+) | TODO

    if sum(size(im_seg1)~=size(im_seg2))>0
        disp('im_seg1 and im_seg2 must have the same sizes');
    end

    image_size = size(im_seg1,1)*size(im_seg1,2);

    % Accuracy
    tmp = (im_seg1==im_seg2);
    acc = (sum(tmp(:)) / image_size)*100.0;

    % F-measure
    fm = [];
    for k=1:nb_classes
        im_tmp2 = (im_seg2==k);
        sum2    = sum(im_tmp2(:));
        if sum2>0
            im_tmp1 = (im_seg1==k);
            sum1    = sum(im_tmp1(:));
            sum12   = (sum1 + sum2);
            inter   = (im_tmp1 & im_tmp2);
            cinter  = sum(inter(:));
            if sum12==0
                m = nan;
            else
                m = ((2.0*cinter)/sum12)*100.0;
            end
            fm = [fm m];
        end
    end
    fm = mean(fm);

    % ASASD
    asasd = 0.0;

    % MSASD
    msasd = 0.0;
end