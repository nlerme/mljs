function B = sorti(A, varargin)
% B = sorti(A)
%
% A - Cell array of strings
% B - Sorted output. It's case insensitive as in the operative system. Matlab 
%     sort function uses ASCII dictionary order (first upper case).
%
% Case insensitive sorting of cell array. Takes the same input arguments 
% as SORT
%
% gP 14/1/2013


[~, ix] = sort(lower(A), varargin{:});

B = A(ix);