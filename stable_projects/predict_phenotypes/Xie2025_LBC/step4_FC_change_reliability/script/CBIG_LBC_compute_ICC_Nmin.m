function CBIG_LBC_compute_ICC_Nmin(input_struct_file, subID_txt, output_matfile)
% CBIG_LBC_compute_ICC_Nmin(input_struct_file, subID_txt, output_matfile)
%
% Compute ICC at 5 scan durations (2, 4, 6, 8, 10 min) for Year 0 and Year 2
% by comparing FirstHalf vs LastHalf FC within each year.
%
% Input:
%     - input_struct_file: (string)
%           Path to .mat file produced by CBIG_LBC_extract_FC_Nmin. Contains
%           fields FCY0_FirstHalf_Xmin, FCY0_LastHalf_Xmin, FCY2_FirstHalf_Xmin,
%           FCY2_LastHalf_Xmin for X in {2min, 4min, 6min, 8min, 10min}.
%
%     - subID_txt: (string)
%           Path to SubID_4run_final.txt (one subject ID per line).
%
%     - output_matfile: (string)
%           Path to save output .mat file.
%
% Output:
%     - A .mat file saved to output_matfile containing ICC_Y0 and ICC_Y2 structs
%       with fields '2min', '4min', '6min', '8min', '10min' (each n_edges x 1).
%
% Example:
%     CBIG_LBC_compute_ICC_Nmin('FC_struct.mat', 'SubID.txt', 'ICC_results.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% Load FC struct
FC = load(input_struct_file);

% Subject IDs
SubID_4run = CBIG_text2cell(subID_txt);
subjectID  = [SubID_4run; SubID_4run];
k          = 2; % number of repetitions per subject

durations = {'2min', '4min', '6min', '8min', '10min'};

% Preallocate
n_edges = size(FC.FCY0_FirstHalf_2min, 2);
ICC_Y0 = struct();
ICC_Y2 = struct();
for d = 1:length(durations)
    ICC_Y0.(durations{d}) = zeros(n_edges, 1);
    ICC_Y2.(durations{d}) = zeros(n_edges, 1);
end

% Compute ICC per edge
for counter = 1:n_edges
    if mod(counter, 1000) == 0
        fprintf('Processing edge %d / %d\n', counter, n_edges);
    end
    for d = 1:length(durations)
        dur = durations{d};

        Ymat_Y0 = CBIG_StableAtanh([FC.(['FCY0_FirstHalf_' dur])(:, counter); ...
                                     FC.(['FCY0_LastHalf_'  dur])(:, counter)]);
        Ymat_Y2 = CBIG_StableAtanh([FC.(['FCY2_FirstHalf_' dur])(:, counter); ...
                                     FC.(['FCY2_LastHalf_'  dur])(:, counter)]);

        ICC_Y0.(dur)(counter) = CBIG_LBC_compute_ICC_anova1(Ymat_Y0, subjectID, k);
        ICC_Y2.(dur)(counter) = CBIG_LBC_compute_ICC_anova1(Ymat_Y2, subjectID, k);
    end
end

% Save output
save(output_matfile, 'ICC_Y0', 'ICC_Y2', '-v7.3');
fprintf('Saved ICC results to %s\n', output_matfile);

end
