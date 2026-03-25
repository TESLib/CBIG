function CBIG_LBC_combine_FC_Nmin(InputDir, SubID)
% CBIG_LBC_combine_FC_Nmin(InputDir, SubID)
%
% Combine hemisphere and subcortical FC sub-matrices (lh2lh, lh2rh,
% lh2subcort, rh2rh, rh2subcort, subcort2subcort) into a single 419x419
% matrix per time window, then combine FC across runs to produce 6, 8, and
% 10 min combined FC matrices for each subject.
%
% Input:
%     - InputDir: (string)
%           Base directory containing per-subject FC_metrics subdirectories.
%
%     - SubID: (string)
%           Path to text file with one subject ID per line.
%
% Output:
%     - Per-subject combined FC .mat files saved under [InputDir]/<subID>/FC_metrics/.
%       Includes Run1_2min.mat, Run1_4min.mat, Run1_5min.mat, Run2_1min.mat,
%       Run2_3min.mat, Run2_5min.mat, Combined_6min.mat, Combined_8min.mat,
%       Combined_10min.mat.
%
% Example:
%     CBIG_LBC_combine_FC_Nmin('/path/to/FCY0_FirstHalf_Nmin', 'SubID.txt')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
%% Setup
SubID_4run = CBIG_text2cell(SubID);
TimeWindow = {'Run1_2min'; 'Run1_4min'; 'Run1_5min'; 'Run2_1min'; 'Run2_3min'; 'Run2_5min'};
FailedIndex = zeros(length(SubID_4run), 1);

%% Loop over subjects
for ID = 1:length(SubID_4run)
    fprintf('Processing subject %d: %s\n', ID, SubID_4run{ID});
    FC_10min = fullfile(InputDir, SubID_4run{ID}, 'FC_metrics','Combined_10min.mat');
    if exist(FC_10min, 'file') == 2
        fprintf('Subject %s already processed (Combined_10min.mat exists). Skipping subject.\n', SubID_4run{ID});
        continue;
    end
    % Loop over time windows for FC metrics combination
    for Nmin = 1:length(TimeWindow)
        % Build file pattern for the current time window
        OutputFile = fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', [TimeWindow{Nmin} '.mat']);
        FilePattern = fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', TimeWindow{Nmin}, '*.mat');
        
        % List all files matching the pattern
        Files = dir(FilePattern);
        if isempty(Files)
            warning('No files found in %s. Skipping subject %s, time window %s.', ...
                FilePattern, SubID_4run{ID}, TimeWindow{Nmin});
            FailedIndex(ID) = 1;
            continue;
        end
        
        % Expected file suffixes and their corresponding field names
        suffixes = {'lh2lh.mat', 'lh2rh.mat', 'lh2subcort.mat', ...
            'rh2rh.mat', 'rh2subcort.mat', 'subcort2subcort.mat'};
        fieldNames = {'lh2lh', 'lh2rh', 'lh2subcort', 'rh2rh', 'rh2subcort', 'subcort2subcort'};
        
        % Load each required file into a structure
        dataStruct = struct();
        for s = 1:length(suffixes)
            % Find the file whose name ends with the desired suffix
            idx = endsWith({Files.name}, suffixes{s});
            if ~any(idx)
                error('No file ending with "%s" found for subject %s, time window %s.', ...
                    suffixes{s}, SubID_4run{ID}, TimeWindow{Nmin});
                FailedIndex(ID) = 1;
            end
            
            % Since only one file is expected to match, load that file directly.
            currFile = fullfile(Files(idx).folder, Files(idx).name);
            dataStruct.(fieldNames{s}) = load(currFile);
        end
        
        %% Combine correlation matrices if not failed
        if FailedIndex(ID) ~= 1
            % Check subcortical matrix dimensions
            if ~isequal(size(dataStruct.subcort2subcort.corr_mat), [19, 19])
                error(['The number of subcortical ROIs is not 19 for subject %s, time window %s.' ...
                    ' FC matrix will not be saved.'], SubID_4run{ID}, TimeWindow{Nmin});
            end
            % Combine the matrices
            lh2all = [dataStruct.lh2lh.corr_mat, dataStruct.lh2rh.corr_mat, dataStruct.lh2subcort.corr_mat];
            rh2all = [dataStruct.lh2rh.corr_mat', dataStruct.rh2rh.corr_mat, dataStruct.rh2subcort.corr_mat];
            subcort2all = [dataStruct.lh2subcort.corr_mat', dataStruct.rh2subcort.corr_mat', ...
                dataStruct.subcort2subcort.corr_mat];
            
            corr_mat = [lh2all; rh2all; subcort2all];
            save(OutputFile, 'corr_mat');
%             fprintf('Saved combined FC metrics for subject %s, time window %s.\n', SubID_4run{ID}, TimeWindow{Nmin});
        end
    end
    
    %% Combine FC metrics across different runs for the current subject
    try
        FC_1_5min = load(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', [TimeWindow{3}, '.mat']));
        FC_2_1min = load(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', [TimeWindow{4}, '.mat']));
        FC_2_3min = load(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', [TimeWindow{5}, '.mat']));
        FC_2_5min = load(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics', [TimeWindow{6}, '.mat']));
        
        nframes_5min = 375; % total frames for each run
        nframes_1min = 75;
        nframes_3min = 225;
        % combined 6min
        corr_mat = (nframes_5min / (nframes_5min + nframes_1min)) * CBIG_StableAtanh(FC_1_5min.corr_mat) + ...
            (nframes_1min / (nframes_5min + nframes_1min)) *CBIG_StableAtanh(FC_2_1min.corr_mat);
        corr_mat = tanh(corr_mat);
        save(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics','Combined_6min.mat'),'corr_mat')

        % combined 8min
        corr_mat = (nframes_5min / (nframes_5min + nframes_3min)) * CBIG_StableAtanh(FC_1_5min.corr_mat) + ...
            (nframes_3min / (nframes_5min + nframes_3min)) * CBIG_StableAtanh(FC_2_3min.corr_mat);
        corr_mat = tanh(corr_mat);
        save(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics','Combined_8min.mat'),'corr_mat')

        % combined 10min
        corr_mat = 0.5 * CBIG_StableAtanh(FC_1_5min.corr_mat) + 0.5 * CBIG_StableAtanh(FC_2_5min.corr_mat);
        corr_mat = tanh(corr_mat);
        save(fullfile(InputDir, SubID_4run{ID}, 'FC_metrics','Combined_10min.mat'),'corr_mat')
        
%         fprintf('Saved combined FC metrics across runs for subject %s.\n', SubID_4run{ID});
    catch ME
        warning('Error combining FC metrics for subject %s: %s', SubID_4run{ID}, ME.message);
        FailedIndex(ID) = 1;
    end
    
end
if sum(FailedIndex) >= 1
    
    % Get indices of failed subjects
    FailedIdx = find(FailedIndex);
    
    % Extract the corresponding subject IDs (as a cell array)
    FailedSub = SubID_4run(FailedIdx);
    % Define output file names; here I place them in the common FC_metrics folder.
    % (You can change the path as needed.)
    OutFile_txt = fullfile(InputDir, 'FailedSub.txt');
    OutFile_mat = fullfile(InputDir, 'FailedSub.mat');
    
    % Save the failed subjects as text (using CBIG_cell2text)
    CBIG_cell2text(FailedSub, OutFile_txt);
    
    % Also save as a MAT file
    save(OutFile_mat, 'FailedSub', 'FailedIndex');
    
    fprintf('Saved failed subject list to %s and %s.\n', OutFile_txt, OutFile_mat);
else
    fprintf('No failed subject.\n');
end
end

