function [num_selected, original_num_param, percent_kept, original_num_points, mean_distance] = data_select_full(varargin)
% This script is for creation of input files using the brips method in
% Perseus homology software: http://www.sas.upenn.edu/~vnanda/perseus/
% Outputs:
% - num_selected = number of data columns chosen in new basis to amount for
%   percent_var of variance in the new data
% - original_num_param = number of variables in original data
% - percent_kept = percent of data points kept after removing due to
% insufficient number of non-empty values
% - original_num_points = original number of data points in the file
% - mean_distance = average distance between selected points in the new basis
% - modified data is saved to a text file entitled out_base_name
% Inputs: 
% - mandatory filename = name of file containing data to analyze
% - mandatory out_base_name = base string for outputing selected data after pca
% - optional percent_var = percent variable to account for in new data
% - optional init_rad = initial radius of n-spheres for use in perseus
% homology software
% - optional max_steps = number of steps to run perseus on data file
% - optional nonempty_threshold = percent of parameters in data point
% required to be non-empty in order for the point to be considered
% Note:
% - Input data must be of the form where rows are the data points and
% columns are the parameters of the data (i.e. each row is a language and
% each column is a syntactic parameter)
% Example use:
% [num_sel,total_original_param]=data_select('raw data.txt','output_test',0.6)

if nargin==0
    error('Error: No input provided.')
else
    % Process inputs and perform error checking
    filename = varargin{1};
    if ischar(filename) == 0
        error('Error: Provided file name must be type char.')
    end
    out_base_name  = varargin{2};
    if ischar(out_base_name) == 0
        error('Error: Provided file name must be type char.')
    end
    percent_var = 1;
    init_rad = 0;
    max_steps = 100;
    nonempty_threshold = 0;
    if nargin > 2 && nargin < 7
        percent_var = varargin{3};
        if isnumeric(percent_var) == 0
            error('Error: Provided value for percent variance must be numeric.')
        end
        if length(percent_var) > 1
            error('Error: Input for percent variance must a single number.')
        end
        if percent_var < 0 || percent_var > 1
            error('Error: Percent variance must be between 0 and 1.')
        end
        if nargin > 3 && nargin < 7
            init_rad = varargin{4};
            if isnumeric(init_rad) == 0
                error('Error: Provided value for initial radius must be numeric.')
            end
            if length(init_rad) > 1
                error('Error: Input for initial radius must a single number.')
            end
            if init_rad < 0
                error('Error: Initial radius must be greater than or equal to zero.')
            end
        end
        if nargin > 4
            max_steps = varargin{5};
            if isnumeric(max_steps) == 0
                error('Error: Provided value for maximum steps must be numeric.')
            end 
            if length(max_steps) > 1
                error('Error: Input for maximum steps must a single number.')
            end
            if ~(max_steps == round(max_steps))
                error('Error: Input for maximum steps must an integer.')
            end
            if max_steps <= 0
                error('Error: Maximum steps must be greater than or equal to zero.')
            end
        end
        if nargin == 6
            nonempty_threshold = varargin{6};
            if isnumeric(nonempty_threshold) == 0
                error('Error: Provided value for non-empty threshold must be numeric.')
            end
            if length(nonempty_threshold) > 1
                error('Error: Input for non-empty threshold must a single number.')
            end
            if nonempty_threshold < 0 || percent_var > 1
                error('Error: Non-empty threshold must be between 0 and 1.')
            end
        end
    end
    if nargin == 1
        error('Error: Not enough inputs. Must provide between 2 and 6 inputs.')
    end
    if nargin > 6
        error('Error: Too many inputs. Must provide between 2 and 6 inputs.')
    end
    
    % Load the data
    if ~exist(filename)
        error('Error: File with requested filename not found.')
    end
    raw_data = thresh_data(load(filename), nonempty_threshold);
    temp = size(raw_data);
    temp_old = size(load(filename));
    len = temp(1);
    original_num_param = temp(2);
    
    % Process and select the data
    [COEFF,SCORE,e] = pca(raw_data);
    percent_kept = len/temp_old(1);
    original_num_points = temp_old(1);
    index = 0;
    while sum(e(1:index))/sum(e) < percent_var
    	index = index + 1;
    end
    num_selected = index;
    NewCol = ones(len, 1)*init_rad;
    out_data = [SCORE(:,1:num_selected) NewCol];
    out_round = round(out_data*1e2)/1e2;
    
    % Find the average disance between points in the new basis
    Cut = SCORE(:,[1:num_selected]);
    d_mat = zeros(len,len);
    for i = 1 : len
        for j = i : len
            d_mat(i,j) = sqrt(sum((Cut(i,:) - Cut(j,:)) .^ 2));
        end
    end
    mean_distance = mean(mean(d_mat));
    
    % Write the data to a file
    out_name = strcat(out_base_name,'.txt');
    dlmwrite(out_name,[num_selected],'delimiter',' ');
    dlmwrite(out_name,[1, mean_distance/100, max_steps],'-append','delimiter',' ');
    dlmwrite(out_name,out_round,'-append','delimiter',' ');
end
    

function [new_data] = thresh_data(data, nonempty_threshold)
temp = size(data);
len = temp(1);
data_temp = [];
for index = 1:len
    if percent_nonempty(data(index,:)) >= nonempty_threshold
        temp_new = size(data_temp);
        len_new = temp_new(1);
        if len_new == 0
            data_temp = data(index,:);
        else
            data_temp = [data_temp; data(index,:)];
        end
    end
end
new_data = data_temp;

function [percent] = percent_nonempty(data_point)
nonempty = 0;
total = length(data_point);
for index = 1:total
    if data_point(index) == 0 || data_point(index) == 1
        nonempty = nonempty + 1;
    end
percent = nonempty / total;
end