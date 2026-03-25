function CBIG_LBC_compute_cog_change_std(cogY0_path,...
                                         CogChange_path,...
                                         resid_mat_path,...
                                         std_mat_path)
% CBIG_LBC_compute_cog_change_std(cogY0_path, CogChange_path, resid_mat_path, std_mat_path)
%
% Regress out covariates (baseline age, age interval, sex) from cognitive
% change scores, normalize by Year 0 standard deviation, and save
% residuals and standard deviation.
%
% Input:
%     - cogY0_path: (string)
%           Full path to cogY0 harmonized .csv file.
%
%     - CogChange_path: (string)
%           Full path to CogChange harmonized .csv file.
%
%     - resid_mat_path: (string)
%           Full path to save residual matrix (.mat, variable: cog_change_resid_z).
%
%     - std_mat_path: (string)
%           Full path to save standard deviation vector (.mat, variable: cog_change_std).
%
% Output:
%     - .mat files saved to resid_mat_path and std_mat_path.
%
% Example:
%     CBIG_LBC_compute_cog_change_std('cogY0.csv', 'CogChange.csv', 'resid.mat', 'std.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
%% Load data
cog_change = readtable(CogChange_path);
cog_change_score = cog_change{:, 15:22};



age_y0 = cog_change{:, 12};
age_interval = cog_change{:, 13};

sex = cog_change{:, 7};
sex_dummy = zeros(size(sex));
sex_dummy(strcmp(sex, 'F')) = 1;
sex_dummy(strcmp(sex, 'M')) = 0;

regressors = [age_y0, age_interval, sex_dummy];
n_subjects = size(cog_change_score, 1);
cog_change_resid = zeros(n_subjects, 8);

%% Regress out covariates and compute adjusted residuals
for i = 1:8
    lm = fitlm(regressors, cog_change_score(:, i));
    cog_change_resid(:, i) = lm.Residuals.Raw + lm.Coefficients.Estimate(1);
end
CogMeasures_Y0 = readtable(cogY0_path);
CogY0 = CogMeasures_Y0{:,15:22};
CogY0_std = std(CogY0);

cog_change_resid_z = cog_change_resid./repmat(CogY0_std,length(cog_change_resid),1);

%% Save residuals and std
save(resid_mat_path, 'cog_change_resid_z');

cog_change_std = std(cog_change_resid_z);
save(std_mat_path, 'cog_change_std');

end
