function im_res = get_diff_segmentation( im_seg, im_gt )
    % Returns segmentation with only false positives (cyan) and false 
    % negatives (magenta) between provided segmentation and ground truth.
    % 
    % Input arguments:
    %   - im_seg : provided segmentation
    %   - im_gt  : ground truth
    % 
    % Output arguments:
    %   - im_res : resulting segmentation

    im_res = uint8(zeros(size(im_seg)));

    for i=1:size(im_seg,1)
        for j=1:size(im_seg,2)
            if im_gt(i,j)==2 && im_seg(i,j)==1
                im_res(i,j) = 5;
            elseif im_gt(i,j)==1 && im_seg(i,j)==2
                im_res(i,j) = 6;
            end
        end
    end
end