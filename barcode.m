function n = barcode(varargin)
% This script is for creation of barcode graphs using data files output by
% Perseus homology software: http://www.sas.upenn.edu/~vnanda/perseus/
% Outputs:
% - n = number of persistence intervals
% Inputs: 
% - mandatory 1st argument:
%   Base filename used for the output data (i.e. all filenames are of the
%   form filename_0.txt, filename_1.txt, ...)
% - optional 2nd argument:
%   A numeric arrray of length 1 or 2. If length 1, then this is the step
%   size for increase in radius per step. If length 2, then first element
%   is step size and second element is starting step number or radius. Note: if 
%   step size is -1, this forces the display to be in number of steps,
%   otherwise the step size must be greater than 0.
% - optional 3rd argument:
%   A numeric array that represents the values of the files to display
%   in the barcode graph
% Example uses:
% barcode('test_data',0.02)
% barcode('data_14_test',[0.01,0.6],[1,2])

% Initialize the program and do error processing
if nargin==0
    n = -1;
    error('Error: No input provided.')
else
    filename = varargin{1};
    if ischar(filename) == 0
        error('Error: Provided file name must be type char.')
    end
    
    x_scale_mod = 1;
    x_displacement = 0;
    plot_type = 0;
    if nargin == 2 || nargin == 3
        if ~isnumeric(varargin{2})
            if length(varargin{2}) == 1
                error('Error: Provided step size must be a value of type double.')
            end
            if length(varargin{2}) == 2
                error('Error: Provided step size and intial radius must be a value of type double.')
            end
            if length(varargin{2}) > 2
                error('Error: Second argument must be an array of type double.')
            end
                
        else
            if length(varargin{2}) > 2
                error('Error: Provided second argument is too long. Must be length 1 or 2.')
            else
                arg_two = varargin{2};
                step_size = arg_two(1);
                if length(varargin{2}) == 2
                    x_displacement = arg_two(2);
                end
                plot_type = 1;
                if step_size == -1
                    plot_type = 0;
                    step_size = 1;
                end
                if step_size <= 0
                    error('Error: Provide step size must be a double greater than 0 (or -1 to force steps instead of size).')
                end
                if x_displacement < 0
                    if plot_type == 0
                        error('Error: Initial step number must be greater than 0.')
                    else
                        error('Error: Initial radius must be greater than 0.')
                    end
                end
            end
        end
        x_scale_mod = step_size;
    end
    if nargin == 3
        if ~isnumeric(varargin{3})
            error('Error: Provided search list must be an array with elements of type double.')
        else
            subset = sort(varargin{3});
            found = [];
            for index = 1:length(subset)
                if ismember(subset(index),found)
                    error('Error: Duplicate entry in provided homology subset array.')
                else
                    found = [found subset(index)];
                end
            end
        end
    end
    if nargin > 3
        error('Error: Too many inputs. Must provide between 1 and 3 inputs.')
    end

    % find the number of files
    if nargin == 1 || nargin == 2
        num_file = 0;
        while exist(strcat(filename, '_', num2str(num_file), '.txt'))
            num_file = num_file + 1;
        end
        subset = zeros(num_file,1);
        for index = 1:num_file
            subset(index) = index-1;
        end
    end
    if nargin == 3
        num_file = 0;
        while num_file <= max(subset)
            if ~exist(strcat(filename, '_', num2str(num_file), '.txt')) && ismember(num_file, subset)
                error('Error: One or more of the requested homology groups does not have associated data.')
            else
                num_file = num_file + 1;
            end
        end
    end

    if num_file == 0
        error('Error: Provided file name not found.')
    end

    % extract birth and death indices
    ints = cell(num_file, 1);
    births = cell(num_file, 1);
    deaths = cell(num_file, 1);
    total_lines = 0;
    max_death = 0;
    for index = 1:num_file
        if exist(strcat(filename, '_', num2str(index-1), '.txt')) && ismember(index-1,subset)
            ints{index} = load(strcat(filename, '_', num2str(index-1), '.txt'));
        end
        if isempty(ints{index}) == 0
            temp = ints{index};
            births{index} = temp(:,1);
            deaths{index} = temp(:,2);
            total_lines = total_lines + length(births{index});
            if index > min(subset) && index < num_file
                found_more_data = 0;
                for jndex = index+1:num_file
                    if exist(strcat(filename, '_', num2str(jndex-1), '.txt')) && ismember(jndex-1,subset)
                        temp_data = load(strcat(filename, '_', num2str(jndex-1), '.txt'));
                        if ~isempty(temp_data)
                            found_more_data = 1;
                            break
                        end
                    end
                end
                if found_more_data == 1
                    total_lines = total_lines + 1;
                end
            end
            if max(deaths{index}) > max_death
                max_death = max(deaths{index});
            end
        end
    end
    
    % Check to make sure data is non-empty
    found_data = 0;
    for index = 1:num_file
        if ~isempty(ints{index})
            found_data = 1;
        end
    end
    if found_data == 0
        error('Error: All selected data files were empty.')
    end
    
    % Check to see if the value of max_death is greater than 0
    max_birth = 0;
    for index = 1:num_file
        if ~isempty(births{index})
            temp_max = max(births{index});
            if temp_max > max_birth
                max_birth = temp_max;
            end
        end
    end
    if max_birth == 0
        error('Error: An unknown error occured.')
    end
    if max_death < max_birth
        max_death = max_birth*1.1;
    end

    % Create graph data
    p=figure();
    hold on
    x = zeros(1, 2*total_lines);
    y = zeros(1, 2*total_lines);
    type = zeros(1, total_lines);
    displacement = 0;

    % Create y data
    for index = 1:total_lines
        y(2*index-1) = (total_lines - index + 1) / (total_lines + 1);
        y(2*index) = (total_lines - index + 1) / (total_lines + 1);
    end

    % Find minimum birth value for low end of graph
    min_birth = max_death;
    for i = 1:num_file
        if isempty(ints{i}) == 0
            if min_birth > min(births{i})*x_scale_mod+ x_displacement
                min_birth = min(births{i})*x_scale_mod + x_displacement;
            end
        end
    end
    
    % Create x data
    for i = 1:num_file
        if isempty(ints{i}) == 0
            if i > min(subset) + 1
                x(displacement - 1) = min_birth;
                x(displacement) = 1.1 * max_death * x_scale_mod + x_displacement;
                type(displacement/2) = 1;
            end
            births_temp = births{i};
            deaths_temp = deaths{i};
            for index = 1:length(births_temp)
                x(2*index-1+displacement) = births_temp(index) * x_scale_mod + x_displacement;
                if deaths_temp(index) == -1
                    x(2*index+displacement) = 1.1 * max_death * x_scale_mod + x_displacement;
                else
                    x(2*index+displacement) = deaths_temp(index) * x_scale_mod + x_displacement;
                end
            end
            displacement = displacement + 2*length(births_temp) + 2;
        end
    end
    
    % Place the y-labels
    displacement = 0;
    for i = 1:num_file
        if isempty(ints{i}) == 0
            births_temp = births{i};
            mid = (y(1+displacement)+y(2*length(births_temp)-1+displacement))/2;
            text(-0.1*(max(x)-min(x))+min(x), mid, strcat('H_', num2str(i-1)),'FontSize',20)
            displacement = displacement + 2*length(births_temp) + 2;
        end
    end

    % Draw lines on graph
    for index = 1:total_lines
        drawLine([x(2*index-1) y(2*index-1)], [x(2*index) y(2*index)], type(index), min(x), max(x))
    end
    set(gcf,'renderer','zbuffer');
    xlim([min(x) max(x)])
    if plot_type == 0
        xlabel('Number of steps')
    else
        xlabel('Increase in n-sphere radius')
    end
    ylim([0 1])
    set(gca, 'YTick', []);

    % Return value
    num_int = 0;
    for i = 1:num_file
        num_int = num_int + length(births{i});
    end
    n = num_int;
end


function [] = drawLine(p1, p2, type, min_x, max_x)
x = linspace(p1(1), p2(1));
y = x;
for index = 1:length(y)
    y(index) = p1(2);
end
if type == 0
    plot(x,y)
else
    plot(x, y, '--')
end
if p2(1) == max_x && type == 0
    drawArrow(p2(1), p2(2), (max_x-min_x)/50)
end

function [] = drawArrow(px, py, scale)
x = linspace(px-scale, px);
y1 = x;
y2 = x;
for index = 1:length(y1)
    y1(index) = py + 0.015*(length(y1)-index)/length(y1);
    y2(index) = py - 0.015*(length(y1)-index)/length(y1);
end
plot(x,y1)
plot(x,y2)