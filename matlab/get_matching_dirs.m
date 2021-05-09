function files_list = get_matching_dirs(path, pattern)
    % This function returns the directories matching a given pattern
    %
    % directory : directory where the search is performed
    % pattern : regular expression for matching the desired directories

    tmp = dir(path);
    files_list = {};

    for i={tmp([tmp.isdir]).name}
        c = regexp(i, pattern, 'match', 'ignorecase');
        if length(c{:})>0 && ~strcmp(i, '.') && ~strcmp(i, '..')
            f = [sprintf('%s%s%s', path, filesep, i{1})];
            files_list = {files_list{:},f};
        end
    end

    files_list = sorti(files_list);
end