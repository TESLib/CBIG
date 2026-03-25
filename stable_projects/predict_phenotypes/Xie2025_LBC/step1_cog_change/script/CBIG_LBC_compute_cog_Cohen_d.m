function CBIG_LBC_compute_cog_Cohen_d(path_Y0, path_Y2, save_path)
% CBIG_LBC_compute_cog_Cohen_d(path_Y0, path_Y2, save_path)
%
% Compute effect size (Cohen's d) for the longAge term in the longitudinal
% mixed-effects cognitive change model.
%
% Input:
%     - path_Y0: (string)
%           Path to harmonized cognition .csv file at Year 0.
%
%     - path_Y2: (string)
%           Path to harmonized cognition .csv file at Year 2.
%
%     - save_path: (string)
%           Full path to save results (.mat).
%
% Output:
%     - A .mat file saved to save_path containing 't', 'p', 'd_long', and
%       'fdr_index'.
%
% Example:
%     CBIG_LBC_compute_cog_Cohen_d('DemoCog_Y0.csv', 'DemoCog_Y2.csv', 'cohen_d.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
%% Read input
cog_measures_Y0 = readtable(path_Y0);
cog_measures_Y2 = readtable(path_Y2);

% Concatenate data from Y0 and Y2
Data = [cog_measures_Y0(:,1:14); cog_measures_Y2(:,1:14)];
DVars = [cog_measures_Y0(:,15:22); cog_measures_Y2(:,15:22)];

% Initialize output
p = zeros(1,8);
t = zeros(1,8);

% Fit LME for each cognitive variable
for counter = 1:8
    Data.Dvar = DVars{:,counter}; 
    LME1 = fitlme(Data, 'Dvar ~ crossAge + longAge + sex + (1|src_subject_id)', 'FitMethod', 'REML');
    
    t(counter) = LME1.Coefficients.tStat(4);     % longAge t-stat
    p(counter) = LME1.Coefficients.pValue(4);    % longAge p-value
end

% Compute Cohen's d
d_long = t ./ sqrt(height(cog_measures_Y0));
%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05, p);
% Save results
save(save_path, 't', 'p', 'd_long','fdr_index');

end
