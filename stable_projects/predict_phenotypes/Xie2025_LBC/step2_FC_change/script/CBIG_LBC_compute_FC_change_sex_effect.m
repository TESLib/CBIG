function CBIG_LBC_compute_FC_change_sex_effect(start_N, end_N, FC_path, path_Y0, path_Y2, save_path)
% CBIG_LBC_compute_FC_change_sex_effect(start_N, end_N, FC_path, path_Y0, path_Y2, save_path)
%
% Compute sex effect on FC change for a chunk of FC edges using a longitudinal
% mixed-effects model with a longAge x sex interaction term.
%
% Input:
%     - start_N: (scalar)
%           Start index of the FC edge chunk.
%
%     - end_N: (scalar)
%           End index of the FC edge chunk.
%
%     - FC_path: (string)
%           Path to FC_Y0Y2_combat.csv file.
%
%     - path_Y0: (string)
%           Path to demographic + cognition .csv file at Year 0.
%
%     - path_Y2: (string)
%           Path to demographic + cognition .csv file at Year 2.
%
%     - save_path: (string)
%           Full path to save results (.mat).
%
% Output:
%     - A .mat file saved to save_path containing 't', 'p', and 'b'
%       (each 3 x chunk_size): rows correspond to [male longAge, sex
%       interaction, female longAge (combined)].
%
% Example:
%     CBIG_LBC_compute_FC_change_sex_effect(1, 1000, 'FC_combat.csv', ...
%         'DemoCog_Y0.csv', 'DemoCog_Y2.csv', 'sex_effect_chunk1.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Load FC_combat 
FC_combat = readtable(FC_path);  

%% Load demographic info
CogMeasures_Y0 = readtable(path_Y0);
CogMeasures_Y2 = readtable(path_Y2);
CogMeasures_Y0.ageY0_centered = CogMeasures_Y0.crossAge - mean(CogMeasures_Y0.crossAge);
CogMeasures_Y2.ageY0_centered = CogMeasures_Y0.ageY0_centered;

% Concatenate data from Y0 and Y2
Data = [CogMeasures_Y0; CogMeasures_Y2];
DVars = FC_combat{:,4:end};
clear FC_combat

% Subset to this chunk only
DVars = DVars(:, start_N:end_N);
chunk_size = end_N - start_N + 1;

% Initialize output (chunk-sized, not full 87571)
p = zeros(3, chunk_size);
t = zeros(3, chunk_size);
b = zeros(3, chunk_size);

% indices for 'longAge' and the interaction term.
i_age = [0   0   0   1   0   0];
i_int = [0   0   0   0   0   1];

% Create the contrast vector 'L' to specify the sum (longAge + sex_F:longAge)
L = i_age + i_int;

% Fit LME for each FC edge in this chunk
for counter = 1:chunk_size

    Data.Dvar = DVars(:, counter);
    LME1 = fitlme(Data, 'Dvar ~ ageY0_centered + longAge*sex + MeanFD + (1 + longAge|src_subject_id)', ...
        'FitMethod', 'REML');
    t(1:2, counter) = LME1.Coefficients.tStat([4 6]);
    p(1:2, counter) = LME1.Coefficients.pValue([4 6]);
    b(1:2, counter) = LME1.Coefficients.Estimate([4 6]);

    % calcuate female longAge statistic
    % 1. Get the coefficient estimates from the fitted model
    beta_estimates = LME1.Coefficients.Estimate;

    % 2. Use coefTest to get the p-value and F-statistic for the hypothesis L*beta=0
    [p_val, F] = coefTest(LME1, L, 0);

    % 3. Calculate the combined estimate and the corresponding t-statistic
    b_female_slope = L * beta_estimates; % This is (longAge+sex_F:longAge)
    t_val = sign(b_female_slope) * sqrt(F); % Restore sign to the t-statistic

    % 4. Store the results for this iteration
    t(3, counter) = t_val;
    p(3, counter) = p_val;
    b(3, counter) = b_female_slope;

end


% Save results
save(save_path, 't', 'p','b','-v7.3');


end
