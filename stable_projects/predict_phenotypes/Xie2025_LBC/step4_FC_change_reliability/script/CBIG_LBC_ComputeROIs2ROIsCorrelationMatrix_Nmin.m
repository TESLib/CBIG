function CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(output_file, subj_text_list1, subj_text_list2, ...
    discard_frames_list, ROIs1, ROIs2, regression_mask1, regression_mask2, all_comb_bool)
% CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(output_file, subj_text_list1, subj_text_list2,
%     discard_frames_list, ROIs1, ROIs2, regression_mask1, regression_mask2, all_comb_bool)
%
% Compute ROI-to-ROI Pearson correlation matrices for truncated scan durations
% across multiple time windows (Run1_2min, Run1_4min, Run1_5min, Run2_1min,
% Run2_3min, Run2_5min). Results are saved per time window in subfolders.
% Adapted from CBIG_ComputeROIs2ROIsCorrelationMatrix.
%
% Input:
%     - output_file: (string)
%           Full path for the output .mat file (used to determine directory;
%           each time window saved in a subdirectory).
%
%     - subj_text_list1: (string)
%           Text file with one subject's fMRI run paths per line (space-separated
%           if multiple runs). Files can be .nii.gz or .dtseries.nii.
%
%     - subj_text_list2: (string)
%           Same format as subj_text_list1. Must have the same number of subjects.
%
%     - discard_frames_list: (string)
%           Text file with discarded frames files (one per subject, space-separated
%           for multiple runs), or 'NONE' to skip motion scrubbing.
%
%     - ROIs1: (string)
%           ROI specification for the first list: a single .annot/.dlabel.nii/
%           .label/.nii.gz file, or a text file listing ROI paths.
%
%     - ROIs2: (string)
%           Same format as ROIs1.
%
%     - regression_mask1: (string or cell)
%           Regression mask for list 1: a .mat file containing 'regress_cell',
%           a 1xK cell of binary voxel masks, or 'NONE'.
%
%     - regression_mask2: (string or cell)
%           Same format as regression_mask1.
%
%     - all_comb_bool: (scalar)
%           If 1, compute all N x M combinations of ROIs1 and ROIs2 (output
%           is N x M x #subjects). If 0, compute paired ROIs only.
%
% Output:
%     - Per-time-window .mat files saved under subdirectories of output_file's
%       parent directory (e.g., Run1_2min/, Run1_4min/, ...).
%
% Example:
%     CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin('out/lh2lh.mat', ...
%         'lh_runs.txt', 'lh_runs.txt', 'NONE', 'lh.annot', 'lh.annot', 'NONE', 'NONE', 1)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

if(ischar(all_comb_bool))
    all_comb_bool = str2double(all_comb_bool);
end

% if(ischar(avg_sub_bool))
%     avg_sub_bool = str2double(avg_sub_bool);
% end

%% read in subject_lists
subj_list_1 = read_sub_list(subj_text_list1);
subj_list_2 = read_sub_list(subj_text_list2);

if(length(subj_list_1) ~= length(subj_list_2))
    error('both lists should contain the same number of subjects');
end

%% read in discarded frames file name
if strcmp(discard_frames_list, 'NONE')
    frame = 0;
else
    frame = 1;
    discard_list = read_sub_list(discard_frames_list);
    if (length(discard_list) ~= length(subj_list_1))
        error('number of subjects in discard list should be the same as that of subjects');
    end
end

%% read in ROIs
ROIs1_cell = read_ROI_list(ROIs1);
ROIs2_cell = read_ROI_list(ROIs2);

%% read in regression list
[regress_cell1, regress1] = read_regress_list(regression_mask1);
[regress_cell2, regress2] = read_regress_list(regression_mask2);

%% space allocation
% if avg_sub_bool == 1
%     if all_comb_bool == 1
%         corr_mat = zeros(length(ROIs1_cell), length(ROIs2_cell));
%     else
%         if length(ROIs1_cell) ~= length(ROIs2_cell)
%             error('ROIs1_cell should have the same length as ROIs2_cell when all_comb_bool = 0');
%         end
%         corr_mat = zeros(length(ROIs1_cell), 1);
%     end % end if all_comb_bool = 1
% else
if all_comb_bool == 1
    corr_mat = zeros(length(ROIs1_cell), length(ROIs2_cell), length(subj_list_1));
else
    if length(ROIs1_cell) ~= length(ROIs2_cell)
        error('ROIs1_cell should have the same length as ROIs2_cell when all_comb_bool = 0');
    end
    corr_mat = zeros(length(ROIs1_cell), length(subj_list_1));
end
% end % end if avg_sub_bool = 1

%% Compute correlation
for i = 1:length(subj_list_1) % loop through each subject
    disp(num2str(i));
    
    S1 = textscan(subj_list_1{i}, '%s');
    S1 = S1{1}; % a cell of size (#runs x 1) for subject i in the first list
    
    S2 = textscan(subj_list_2{i}, '%s');
    S2 = S2{1}; % a cell of size (#runs x 1) for subject i in the second list
    
    if frame
        discard = textscan(discard_list{i}, '%s');
        discard = discard{1}; % a cell of size (#runs x 1) for subject i in the discard list
    end
    
    %% load time series and truncate into Nmin
    %  run 1
    
    % Start a named timer
    
    if frame
        discard_file = discard{1};
        fid = fopen(discard_file, 'r');
        frame_index = fscanf(fid,'%d');
    end
    
    input = S1{1};
    if (isempty(strfind(input, '.dtseries.nii'))) % input is a nifti file: .nii.gz
        input_series = MRIread(input);
        % time_course1 will look like nframes x nvertices for e.g. 236 x 10242
        time_course1 = single(transpose(reshape(input_series.vol, ...
            size(input_series.vol, 1) * size(input_series.vol, 2) * size(input_series.vol, 3), ...
            size(input_series.vol, 4))));
    else % input is a cifti file: .dtseries.nii
        input_series = ft_read_cifti(input);
        time_course1 = single(transpose(input_series.dtseries));
    end
    input = S2{1};
    if (isempty(strfind(input, '.dtseries.nii'))) % input is a nifti file: .nii.gz
        input_series = MRIread(input);
        % time_course1 will look like nframes x nvertices for e.g. 236 x 10242
        time_course2 = single(transpose(reshape(input_series.vol, ...
            size(input_series.vol, 1) * size(input_series.vol, 2) * size(input_series.vol, 3), ...
            size(input_series.vol, 4))));
    else % input is a cifti file: .dtseries.nii
        input_series = ft_read_cifti(input);
        time_course2 = single(transpose(input_series.dtseries));
    end
    
    % Trancate run 1: 2min 150 frames,4min 300 frames
    
    time_course1_run1_2min = time_course1(1:150,:);
    time_course1_run1_4min = time_course1(1:300,:);
    time_course1_run1_5min = time_course1;
    
    time_course2_run1_2min = time_course2(1:150,:);
    time_course2_run1_4min = time_course2(1:300,:);
    time_course2_run1_5min = time_course2;
    clear time_course1 time_course2
    if frame
        frame_index_2min = frame_index(1:150);
        time_course1_run1_2min(frame_index_2min==0,:) = [];
        time_course2_run1_2min(frame_index_2min==0,:) = [];
        frame_index_4min = frame_index(1:300);
        time_course1_run1_4min(frame_index_4min==0,:) = [];
        time_course2_run1_4min(frame_index_4min==0,:) = [];
        time_course1_run1_5min(frame_index==0,:) = [];
        time_course2_run1_5min(frame_index==0,:) = [];
    end
    
    % run 2
    if frame
        discard_file = discard{2};
        fid = fopen(discard_file, 'r');
        frame_index = fscanf(fid,'%d');
    end
    
    input = S1{2};
    if (isempty(strfind(input, '.dtseries.nii'))) % input is a nifti file: .nii.gz
        input_series = MRIread(input);
        % time_course1 will look like nframes x nvertices for e.g. 236 x 10242
        time_course1 = single(transpose(reshape(input_series.vol, ...
            size(input_series.vol, 1) * size(input_series.vol, 2) * size(input_series.vol, 3), ...
            size(input_series.vol, 4))));
    else % input is a cifti file: .dtseries.nii
        input_series = ft_read_cifti(input);
        time_course1 = single(transpose(input_series.dtseries));
    end
    input = S2{2};
    if (isempty(strfind(input, '.dtseries.nii'))) % input is a nifti file: .nii.gz
        input_series = MRIread(input);
        % time_course1 will look like nframes x nvertices for e.g. 236 x 10242
        time_course2 = single(transpose(reshape(input_series.vol, ...
            size(input_series.vol, 1) * size(input_series.vol, 2) * size(input_series.vol, 3), ...
            size(input_series.vol, 4))));
    else % input is a cifti file: .dtseries.nii
        input_series = ft_read_cifti(input);
        time_course2 = single(transpose(input_series.dtseries));
    end
    
    % Trancate run 2: 1min 75 frames,3min 225 frames
    time_course1_run2_1min = time_course1(1:75,:);
    time_course1_run2_3min = time_course1(1:225,:);
    time_course1_run2_5min = time_course1;
    
    time_course2_run2_1min = time_course2(1:75,:);
    time_course2_run2_3min = time_course2(1:225,:);
    time_course2_run2_5min = time_course2;
    clear time_course1 time_course2
    if frame
        frame_index_1min = frame_index(1:75);
        time_course1_run2_1min(frame_index_1min==0,:) = [];
        time_course2_run2_1min(frame_index_1min==0,:) = [];
        frame_index_3min = frame_index(1:225);
        time_course1_run2_3min(frame_index_3min==0,:) = [];
        time_course2_run2_3min(frame_index_3min==0,:) = [];
        time_course1_run2_5min(frame_index==0,:) = [];
        time_course2_run2_5min(frame_index==0,:) = [];
    end
    time_course1_all = {time_course1_run1_2min;time_course1_run1_4min;time_course1_run1_5min; ...
        time_course1_run2_1min;time_course1_run2_3min;time_course1_run2_5min};
    time_course2_all = {time_course2_run1_2min;time_course2_run1_4min;time_course2_run1_5min; ...
        time_course2_run2_1min;time_course2_run2_3min;time_course2_run2_5min};
    time_window = cellstr(['Run1_2min';'Run1_4min';'Run1_5min';'Run2_1min';'Run2_3min';'Run2_5min']);
    
    
    
    
    

    for j = 1:length(time_course1_all)
        %%%%%%%%%%%%%
        time_course1 = time_course1_all{j};
        time_course2 = time_course2_all{j};
        %%%%%%%%%%%%%
        % create time_courses based on ROIs
        t_series1 = zeros(size(time_course1, 1), length(ROIs1_cell));
        for k = 1:length(ROIs1_cell)
            t_series1(:,k) = CBIG_nanmean(time_course1(:, ROIs1_cell{k}), 2);
        end
        
        t_series2 = zeros(size(time_course2, 1), length(ROIs2_cell));
        for k = 1: length(ROIs2_cell)
            t_series2(:,k) = CBIG_nanmean(time_course2(:, ROIs2_cell{k}), 2);
        end
        
        % regression
        if(regress1)
            regress_signal = zeros(size(time_course1, 1), length(regress_cell1));
            for k = 1:length(regress_cell1)
                regress_signal(:, k) = CBIG_nanmean(time_course1(:, regress_cell1{k} == 1), 2);
            end
            
            % faster than using glmfit in which we need to loop through
            % all voxels
            X = [ones(size(time_course1, 1), 1) regress_signal];
            pseudo_inverse = pinv(X);
            b = pseudo_inverse*t_series1;
            t_series1 = t_series1 - X*b;
        end
        
        if(regress2)
            regress_signal = zeros(size(time_course2, 1), length(regress_cell2));
            for k = 1:length(regress_cell2)
                regress_signal(:, k) = mean(time_course2(:, regress_cell2{k} == 1), 2);
            end
            
            % faster than using glmfit in which we need to loop through
            % all voxels
            X = [ones(size(time_course2, 1), 1) regress_signal];
            pseudo_inverse = pinv(X);
            b = pseudo_inverse*t_series2;
            t_series2 = t_series2 - X*b;
        end
        
        % normalize series (size of series now is nframes x nvertices)
        t_series1 = bsxfun(@minus, t_series1, mean(t_series1, 1));
        t_series1 = bsxfun(@times, t_series1, 1./sqrt(sum(t_series1.^2, 1)));
        
        t_series2 = bsxfun(@minus, t_series2, mean(t_series2, 1));
        t_series2 = bsxfun(@times, t_series2, 1./sqrt(sum(t_series2.^2, 1)));
        
        % compute correlation
        
        
        if all_comb_bool == 1
            corr_mat(:, :, i) = t_series1' * t_series2;
        else
            corr_mat(:, i) = transpose(sum(t_series1 .* t_series2, 1));
        end
        
        
        %%% Write out results for each time window and generate a flag file
    [output_path, name, ext] = fileparts(output_file);
    % Create a subdirectory for the current time window if it doesn't exist
    timewindow_dir = fullfile(output_path, time_window{j});
    if ~exist(timewindow_dir, 'dir')
        mkdir(timewindow_dir);
    end
    % Define the output file for this time window
    output_file_timewindow = fullfile(timewindow_dir, [name, ext]);
    
    % Save the correlation matrix if the file extension is '.mat'
    if ~isempty(strfind(output_file_timewindow, '.mat'))
        save(output_file_timewindow, 'corr_mat', '-v7.3');
    end

 end % inner for loop for each run j of subject i



    
end % outermost for loop
disp(['isnan: ' num2str(sum(isnan(corr_mat(:)))) ' out of ' num2str(numel(corr_mat))]);


end

%% sub-function to read subject lists
function subj_list = read_sub_list(subject_text_list)
% this function will output a 1xN cell where N is the number of
% subjects in the text_list, each subject will be represented by one
% line in the text file
% NOTE: multiple runs of the same subject will still stay on the same
% line
% Each cell will contain the location of the subject, for e.g.
% '<full_path>/subject1_run1_bold.nii.gz <full_path>/subject1_run2_bold.nii.gz'
fid = fopen(subject_text_list, 'r');
i = 0;
while(1);
    tmp = fgetl(fid);
    if(tmp == -1)
        break
    else
        i = i + 1;
        subj_list{i} = tmp;
    end
end
fclose(fid);
end

%% sub-function to read ROI lists
function ROI_cell = read_ROI_list(ROI_list)
% ROI_list can be a .nii.gz/.mgz/.mgh/.dlabel.nii file contains a parcellation.

% this is for an arbitrary nii.gz file
if(~isempty(strfind(ROI_list, '.nii.gz')) || ~isempty(strfind(ROI_list, '.mgz')) || ~isempty(strfind(ROI_list, '.mgh')))
    ROI_vol = MRIread(ROI_list);
    
    regions = unique(ROI_vol.vol(ROI_vol.vol ~= 0));
    for i = 1:length(regions)
        ROI_cell{i} = find(ROI_vol.vol == regions(i));
    end
    
    % this is for an arbitrary .dlabel.nii file
elseif (~isempty(strfind(ROI_list, '.dlabel.nii')))
    ROI_vol = ft_read_cifti(ROI_list, 'mapname','array');
    regions = unique(ROI_vol.dlabel(ROI_vol.dlabel ~= 0));
    for i = 1:length(regions)
        ROI_cell{i} = find(ROI_vol.dlabel == regions(i));
    end
    
    % it can also be a single .label file
elseif (~isempty(strfind(ROI_list, '.label'))) % input ROI as a single .label file
    tmp = read_label([], ROI_list);
    ROI_cell{1} = tmp(:,1) + 1;
    
elseif (~isempty(strfind(ROI_list, '.annot'))) % input ROI as a single .annot file
    vertex_label = CBIG_read_annotation(ROI_list);
    regions = unique(vertex_label(vertex_label ~= 1));   % exclude medial wall
    for i = 1:length(regions)
        ROI_cell{i} = find(vertex_label == regions(i));
    end
    
else % input ROIs is a list of its locations: .nii.gz, dlabel.nii or .label
    fid = fopen(ROI_list, 'r');
    i = 0;
    while(1);
        tmp = fgetl(fid);
        if(tmp == -1)
            break
        else
            if(~isempty(strfind(tmp, '.nii.gz')) || ~isempty(strfind(tmp, '.mgz')) || ~isempty(strfind(tmp, '.mgh')))
                ROI_vol = MRIread(tmp);
                regions = unique(ROI_vol.vol(ROI_vol.vol ~= 0));
                for n = 1:length(regions)
                    i = i + 1;
                    ROI_cell{i} = find(ROI_vol.vol == regions(n)); % each cell contains a list of vertex's indices
                end
            elseif(~isempty(strfind(tmp, '.dlabel.nii')))
                ROI_vol = ft_read_cifti(tmp, 'mapname','array');
                regions = unique(ROI_vol.dlabel(ROI_vol.dlabel ~= 0));
                for n = 1:length(regions)
                    i = i + 1;
                    ROI_cell{i} = find(ROI_vol.dlabel == regions(n));
                end
            elseif(~isempty(strfind(tmp, '.label')))
                i = i + 1;
                tmp = read_label([], tmp);
                ROI_cell{i} = tmp(:, 1) + 1;
            end
        end
    end % end while
    fclose(fid);
end

end

%% sub-function to read regression lists
function [regress_cell, isRegress] = read_regress_list(regression_mask)
if(strcmp(regression_mask, 'NONE'))
    isRegress = 0;
    regress_cell = [];
else
    isRegress = 1;
    %regression_cell is a existing variable
    if(exist('regression_cell', 'var') == 1)
        regress_cell = regression_mask;
        %regression_cell is a existing .mat file contains a variable regress_cell
    elseif (exist(regression_mask, 'file') == 2)
        load(regression_mask);
    else
        error('regression_cell should be a variable or a .mat file which contains a variable regress_cell');
    end
    
end

end

