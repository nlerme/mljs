% Function loading ground truth
function im_gt = load_ground_truth( gt_root_dir, scene_name )
    im_gt = uint8(dlmread([gt_root_dir filesep scene_name]));
    %disp(sprintf('  + min value=%d', min(im_gt(:))));
    %disp(sprintf('  + max value=%d', max(im_gt(:))));
end