function [num_persist] = run_all(varargin)
% This script is for creation of barcode graphs using data files output by
% Perseus homology software: http://www.sas.upenn.edu/~vnanda/perseus/
% This script assumes the brips input format
% Input files containing raw data should be in following form:
% - in a text file
% - rows are data points
% - columns are parameters 
% - all rows must be the same length with all values filled in
% - all columns must be the same length with all values filled in
% - file should in a subfolder entitled data
% Necessary additional scripts:
% - barcode.m in the same folder as run_all.m
% - dat_select_full.m in the same folder as the raw data file
% Outputs:
% - num_persist = total number of persistence intervals
% Inputs:
% - mandatory 'NameIn':
%   Filename used for the input raw data
% - mandatory 'NameOut':
%   Base filename used for the output data (i.e. all filenames are of the
%   form filename_0.txt, filename_1.txt, ...)
% - optional arguments:
%   - 'pcaVar': percent variable to account for in new data (default 0.5)
%   - 'ParamThresh': percent of parameters in data point required to be 
%       non-empty in order for the point to be considered (default 0.7)
%   - 'InitRadius': nitial radius of n-spheres for use in perseus homology
%       software (default 0)
%   - 'MaxSteps': number of steps to run perseus on data file (default 50)
%   - 'HomologySubset': a numeric array that represents the values of the
%       files to display in the barcode graph (default -1 meaning that all
%       found files will be graphed)
% Note: Optional arguments must appear after the 2 required inputs. They
% must be alternating between the name of the option and the value to be
% assigned to that option
% Example use:
% run_all('raw data','data_9_9_test',...,
% 'pcaVar',0.9,'ParamThresh',0.9,'InitRadius',0,...,
% 'MaxSteps',100,'HomologySubset',-1)
%
% run_all('raw data','data_6_8_test','pcaVar',0.6,'ParamThresh',0.8,'InitRadius',0,'MaxSteps',100,'HomologySubset',-1)

% Set input cell array w/ default values
global input_values
input_values = cell(7,2);
input_values{1,1} = 'NameIn';
input_values{1,2} = '';
input_values{2,1} = 'NameOut';
input_values{2,2} = '';
input_values{3,1} = 'pcaVar';
input_values{3,2} = '0.5';
input_values{4,1} = 'ParamThresh';
input_values{4,2} = '0.7';
input_values{5,1} = 'InitRadius';
input_values{5,2} = '0';
input_values{6,1} = 'MaxSteps';
input_values{6,2} = '50';
input_values{7,1} = 'HomologySubset';
input_values{7,2} = '-1';

% Process input arguments
if nargin < 2
    error('Error: Not enough input arguments. First two arguments are required and must be type char.')
end
if ~ischar(varargin{1})
    error('Error: First argument must be type char.')
end
input_values{1,2} = varargin{1};
if ~ischar(varargin{2})
    error('Error: Second argument must be type char.')
end
input_values{2,2} = varargin{2};
if ~(nargin == 2*round(nargin/2))
    error('Error: Number of input aguments must be even.')
end
i = 3;
while i <= nargin
    if ischar(varargin{i}) == 0
         error('Error: One or more of the arguments is not a valid data type.')
    end
    if ~ismember(varargin{i}, input_values)
        error(['Error: ' varargin{i} ' is not a valid input option.'])
    end
    k_index = keyIndex(varargin{i});
    if isnumeric(varargin{i+1}) == 0
        error('Error: All values for additional options must numeric.')
    end
    input_values{k_index,2} = num2str(varargin{i+1});
    i = i+2;
end
input_values

% Perform principle component analysis on data and select a subset
current_dir = pwd;
delete(strcat(keyValue('NameOut'),'*'))
cd(strcat(current_dir,'/data'))
[num_sel, orig_num_param, perc_kept, orig_num_pnts, mean_distance]=data_select_full(strcat(keyValue('NameIn'),'.txt'),...,
    keyValue('NameOut'),keyValue('pcaVar'),keyValue('InitRadius'),...,
    keyValue('MaxSteps'),keyValue('ParamThresh'));
movefile(strcat(keyValue('NameOut'),'.txt'),current_dir)
cd(current_dir)

% Run perseus data analysis on data
command = ['./perseusMac brips ' keyValue('NameOut') '.txt ' keyValue('NameOut')];
[~,cmdout] = system(command)

% Make the barcode graph
if keyValue('HomologySubset') == -1
    temp_bar = barcode(keyValue('NameOut'),[mean_distance/100,keyValue('InitRadius')]);
else
    temp_bar = barcode(keyValue('NameOut'),[mean_distance/100,keyValue('InitRadius')], keyValue('HomologySubset'));
end
num_persist = temp_bar;

function [value] = keyValue(key)
global input_values
[~, index] = ismember(key, input_values);
if strcmp(key,'NameIn') || strcmp(key,'NameOut')
    value = input_values{index, 2};
else
    value = str2num(input_values{index, 2});
end

function [index] = keyIndex(key)
global input_values
[~, index] = ismember(key, input_values);