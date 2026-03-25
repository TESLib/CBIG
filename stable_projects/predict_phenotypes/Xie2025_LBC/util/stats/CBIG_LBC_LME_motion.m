function CBIG_LBC_LME_motion(path_Y0, path_Y2, save_path, N)

% CBIG_LBC_compute_cog_Cohen_d
% Compute effect size (Cohen's d) for longAge term in cognitive change model.
%
% INPUTS:
%   - path_Y0        : string, path to harmonized cognition file at Year 0
%   - path_Y2        : string, path to harmonized cognition file at Year 2
%   - save_path  : string, path to save .mat file with t, p, and d_long
%   - figure_path    : string, path to save generated barplot (no CI)
%   - N              : sample size (used to compute Cohen's d)
%
% OUTPUTS:
%   Saves 't', 'p', and 'd_long' to .mat file
%   Generates and saves a barplot figure using CBIG_LBC_barplot_basic_noCI

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
d_long = t ./ sqrt(N);

% Save results
save(save_path, 't', 'p', 'd_long');


end