function files_list = get_matching_files(path, pattern)
    % This function returns the files matching a given pattern.
    %
    % path : location where the search is performed
    % pattern : regular expression for matching the desired files

    tmp = dir(path);
    files_list = {};

    for i={tmp(~[tmp.isdir]).name}
        c = regexp(i, pattern, 'match', 'ignorecase');
        if length(c{:})>0
            f = [sprintf('%s%s%s', path, filesep, i{1})];
            files_list = {files_list{:},f};
        end
    end

    files_list = sorti(files_list);
end