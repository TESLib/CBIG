function rho_Y0Y2_reg1 = CBIG_LBC_compute_cog_stability_sex_stratify(...
    path_Y0, path_Y2, save_path, sex)
% rho_Y0Y2_reg1 = CBIG_LBC_compute_cog_stability_sex_stratify(path_Y0, path_Y2, save_path, sex)
%
% Compute residual Spearman correlation of 8 cognitive measures between
% Year 0 and Year 2 after regressing out age, stratified by sex.
%
% Input:
%     - path_Y0: (string)
%           Path to Year 0 harmonized cognition .csv file.
%
%     - path_Y2: (string)
%           Path to Year 2 harmonized cognition .csv file.
%
%     - save_path: (string)
%           Full path to save computed results (.mat).
%
%     - sex: (string)
%           Sex group to analyze: 'F' (female) or 'M' (male).
%
% Output:
%     - rho_Y0Y2_reg1: (8 x 2 matrix)
%           Spearman rho and p-value for each of 8 cognitive measures.
%     - A .mat file saved to save_path containing 'rho_Y0Y2_reg1' and 'fdr_index'.
%
% Example:
%     rho = CBIG_LBC_compute_cog_stability_sex_stratify('DemoCog_Y0.csv', ...
%         'DemoCog_Y2.csv', 'stability_F.mat', 'F')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
%% Load data
cog_measures_Y0 = readtable(path_Y0);
cog_measures_Y2 = readtable(path_Y2);


sex_column = cog_measures_Y0{:,7};

sex_select = zeros(size(sex_column)); 
sex_select(strcmp(sex_column, sex)) = 1;


cog_Y0 = cog_measures_Y0{logical(sex_select),15:22};
cog_Y2 = cog_measures_Y2{logical(sex_select),15:22};
age_Y0 = cog_measures_Y0{logical(sex_select),6};
age_Y2 = cog_measures_Y2{logical(sex_select),6};


regressors_Y0_1 = [age_Y0];
regressors_Y2_1 = [age_Y2];

rho_Y0Y2_reg1 = zeros(8,2);

%% Residual correlation for each measure
for counter = 1:8
    LM_Y0 = fitlm(regressors_Y0_1, cog_Y0(:,counter));
    Y0_resid = LM_Y0.Residuals.Raw;

    LM_Y2 = fitlm(regressors_Y2_1, cog_Y2(:,counter));
    Y2_resid = LM_Y2.Residuals.Raw;

    [rho, pval] = corr(Y0_resid, Y2_resid, 'Type', 'Spearman');
    rho_Y0Y2_reg1(counter, :) = [rho, pval];
end

%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05,rho_Y0Y2_reg1(:,2));

%% Save results
save(save_path, 'rho_Y0Y2_reg1','fdr_index');

end
