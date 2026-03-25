function CBIG_LBC_extract_FC_Nmin(ReliabilityDir, sub_txt, OutputPath)
% CBIG_LBC_extract_FC_Nmin(ReliabilityDir, sub_txt, OutputPath)
%
% Extract FC matrices for all subjects across 4 conditions (FCY0_FirstHalf,
% FCY0_LastHalf, FCY2_FirstHalf, FCY2_LastHalf) and 5 time windows
% (2, 4, 6, 8, 10 min), and save as a struct.
%
% Input:
%     - ReliabilityDir: (string)
%           Base directory containing FCY0_FirstHalf_Nmin, FCY0_LastHalf_Nmin,
%           FCY2_FirstHalf_Nmin, FCY2_LastHalf_Nmin subfolders.
%
%     - sub_txt: (string)
%           Path to text file with one subject ID per line.
%
%     - OutputPath: (string)
%           Output .mat file path.
%
% Output:
%     - A .mat file saved to OutputPath as a struct with fields
%       <condition>_<duration> (e.g., FCY0_FirstHalf_2min), each N x 87571.
%
% Example:
%     CBIG_LBC_extract_FC_Nmin('/path/to/ReliabilityDir', 'SubID.txt', 'FC_struct.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

SubID = CBIG_text2cell(sub_txt);
N = length(SubID);

conditions   = {'FCY0_FirstHalf', 'FCY0_LastHalf', 'FCY2_FirstHalf', 'FCY2_LastHalf'};
time_windows = {'Run1_2min', 'Run1_4min', 'Combined_6min', 'Combined_8min', 'Combined_10min'};
tw_labels    = {'2min',      '4min',      '6min',           '8min',           '10min'};

FC = struct();

for c = 1:length(conditions)
    cond     = conditions{c};
    cond_dir = fullfile(ReliabilityDir, [cond '_Nmin']);

    for t = 1:length(time_windows)
        field_name        = [cond '_' tw_labels{t}];
        FC.(field_name)   = zeros(N, 87571);

        for i = 1:N
            fc_file = fullfile(cond_dir, SubID{i}, 'FC_metrics', [time_windows{t} '.mat']);
            if exist(fc_file, 'file')
                load(fc_file, 'corr_mat');
                FC.(field_name)(i,:) = squareform(corr_mat - diag(diag(corr_mat)));
            else
                warning('Missing FC file for subject %s, condition %s, time window %s.', ...
                    SubID{i}, cond, time_windows{t});
            end
        end
        fprintf('Done: %s\n', field_name);
    end
end

save(OutputPath, '-struct', 'FC', '-v7.3');
fprintf('Saved all FC matrices to %s\n', OutputPath);

end
