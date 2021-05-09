function output = blend_images( im_input, im_mask, alpha )
    % Superimposes a mask on an image with a desired amount of 
    % transparency (alpha in [0,1]). Note that the resulting image is the 
    % same that im_input when im_mask<=0.
    % 
    % Input arguments
    %   - input : input image
    %   - mask  : mask image (must be in uint8 format)
    % 
    % Output arguments
    %   - output : superimposed images
    %

    if any(size(im_input)~=size(im_mask))
        error('Input image and mask must have the same dimensions');
    end

    c = im2double(ind2rgb(double(im_mask), get_colormap()));
    output = im2double(cat(3, im_input, im_input, im_input));
    alphas = alpha*ones(size(im_input));
    alphas(im_mask<=0) = 1.0;
    alphas = cat(3, alphas, alphas, alphas);
    output = alphas.*output + (1.0-alphas).*c;
end