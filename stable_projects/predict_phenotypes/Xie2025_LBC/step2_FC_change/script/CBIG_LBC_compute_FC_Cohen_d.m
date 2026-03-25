function CBIG_LBC_compute_FC_Cohen_d(path_Y0, path_Y2, FC_path, save_path)
% CBIG_LBC_compute_FC_Cohen_d(path_Y0, path_Y2, FC_path, save_path)
%
% Compute effect size (Cohen's d) for the longAge term in the longitudinal
% mixed-effects FC change model.
%
% Input:
%     - path_Y0: (string)
%           Path to Year 0 demographic + cognition .csv file.
%
%     - path_Y2: (string)
%           Path to Year 2 demographic + cognition .csv file.
%
%     - FC_path: (string)
%           Path to FC_Y0Y2_combat.csv (cols 1-3 meta, cols 4:end FC edges).
%
%     - save_path: (string)
%           Full path to save results (.mat).
%
% Output:
%     - A .mat file saved to save_path containing 't', 'p', 'd_long', and
%       'fdr_index'.
%
% Example:
%     CBIG_LBC_compute_FC_Cohen_d('DemoCog_Y0.csv', 'DemoCog_Y2.csv', ...
%         'FC_combat.csv', 'FC_cohen_d.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Load FC_combat 
FC_combat = readtable(FC_path);  
N = height(FC_combat)/2;
%% Load demographic info

CogMeasures_Y0 = readtable(path_Y0);
CogMeasures_Y2 = readtable(path_Y2);

% Concatenate data from Y0 and Y2
Data = [CogMeasures_Y0; CogMeasures_Y2];
DVars = FC_combat{:,4:end};
clear FC_combat

% Initialize output

p = zeros(1,size(DVars,2));
t = zeros(1,size(DVars,2));

% Fit LME for each cognitive variable
for counter = 1:size(DVars,2)
   
    Data.Dvar = DVars(:,counter); 
    LME1 = fitlme(Data, 'Dvar ~ crossAge + longAge + sex + MeanFD + (1|src_subject_id)', 'FitMethod', 'REML');
    
    t(counter) = LME1.Coefficients.tStat(5);     % longAge t-stat
    p(counter) = LME1.Coefficients.pValue(5);    % longAge p-value
end

% Compute Cohen's d
d_long = t ./ sqrt(N);

%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05, p);
% Save results
save(save_path, 't', 'p', 'd_long','fdr_index');

end
