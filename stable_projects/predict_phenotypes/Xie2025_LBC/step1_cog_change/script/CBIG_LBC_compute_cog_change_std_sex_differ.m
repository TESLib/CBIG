function CBIG_LBC_compute_cog_change_std_sex_differ(resid_mat_path_F, resid_mat_path_M, save_path)
% CBIG_LBC_compute_cog_change_std_sex_differ(resid_mat_path_F, resid_mat_path_M, save_path)
%
% Compute sex differences in cognitive change variability using the
% Brown-Forsythe Levene test, and report mean, SD, and SD ratio (Female/Male).
%
% Input:
%     - resid_mat_path_F: (string)
%           Full path to female residual matrix (.mat, variable: CogChange_resid_F).
%
%     - resid_mat_path_M: (string)
%           Full path to male residual matrix (.mat, variable: CogChange_resid_M).
%
%     - save_path: (string)
%           Full path to save results (.mat).
%
% Output:
%     - A .mat file saved to save_path containing 'p_lev', 'mean_M', 'mean_F',
%       'SD_M', 'SD_F', 'SDR', and 'fdr_index'.
%
% Example:
%     CBIG_LBC_compute_cog_change_std_sex_differ('resid_F.mat', 'resid_M.mat', 'sex_diff.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Load data
load(resid_mat_path_F, 'CogChange_resid_F');
load(resid_mat_path_M, 'CogChange_resid_M');

M = size(CogChange_resid_M, 2);  % should be 8
p_lev  = nan(M, 1);
mean_M = nan(M, 1);
mean_F = nan(M, 1);
SD_M   = nan(M, 1);
SD_F   = nan(M, 1);
SDR    = nan(M, 1);  % SD ratio: Female / Male (male reference)

%% Compute sex differences for each cognitive measure
for t = 1:M
    yM = CogChange_resid_M(:, t);
    yF = CogChange_resid_F(:, t);

    % remove NaNs
    yM = yM(~isnan(yM));
    yF = yF(~isnan(yF));

    % Brown-Forsythe Levene test
    y     = [yM; yF];
    group = [ones(numel(yM), 1); 2*ones(numel(yF), 1)];  % 1=Male, 2=Female
    [p, ~] = vartestn(y, group, 'TestType', 'BrownForsythe', 'Display', 'off');
    p_lev(t) = p;

    % mean
    mean_M(t) = mean(yM, 'omitnan');
    mean_F(t) = mean(yF, 'omitnan');

    % SDs
    SD_M(t) = std(yM, 'omitnan');
    SD_F(t) = std(yF, 'omitnan');

    % SD ratio (Female / Male)
    SDR(t) = SD_F(t) / SD_M(t);
end

%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05, p_lev);

%% Save results
save(save_path, 'p_lev', 'mean_M', 'mean_F', 'SD_M', 'SD_F', 'SDR','fdr_index');
end
