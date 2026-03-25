function CBIG_LBC_compute_FC_stability(FC_path, path_Y0, path_Y2, save_path)
% CBIG_LBC_compute_FC_stability(FC_path, path_Y0, path_Y2, save_path)
%
% Compute residual Spearman correlation of each FC edge between Year 0 and
% Year 2 after regressing out age, sex, and head motion.
%
% Input:
%     - FC_path: (string)
%           Path to FC_Y0Y2_combat.csv file (cols 1-3 meta, 4:end FC edges;
%           first N rows = Y0, next N rows = Y2).
%
%     - path_Y0: (string)
%           Path to Year 0 demographic + cognition .csv file.
%
%     - path_Y2: (string)
%           Path to Year 2 demographic + cognition .csv file.
%
%     - save_path: (string)
%           Full path to save results (.mat).
%
% Output:
%     - A .mat file saved to save_path containing 'rho_Y0Y2_reg1' (N_edges x 2,
%       columns: rho and p-value) and 'fdr_index'.
%
% Example:
%     CBIG_LBC_compute_FC_stability('FC_combat.csv', 'DemoCog_Y0.csv', ...
%         'DemoCog_Y2.csv', 'FC_stability.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Load FC_combat 
FC_combat = readtable(FC_path);  

N = height(FC_combat)/2;
FC_final_Y0 = FC_combat{1:N,4:end};
FC_final_Y2 = FC_combat{N+1:end,4:end};
clear FC_combat

%% Extract demographic info for Y0 and Y2
Demo_Y0 = readtable(path_Y0);
Demo_Y2 = readtable(path_Y2);

Age_Y0 = Demo_Y0{:,6};
Age_Y2 = Demo_Y2{:,6};


sex = Demo_Y0{:,7};
sex_dummy = zeros(size(sex));
sex_dummy(strcmp(sex, 'F')) = 1;
sex_dummy(strcmp(sex, 'M')) = 0;

MeanFD_Y0 = Demo_Y0.MeanFD;
MeanFD_Y2 = Demo_Y2.MeanFD;

regressors_Y0_1 = [Age_Y0, sex_dummy, MeanFD_Y0];
regressors_Y2_1 = [Age_Y2, sex_dummy, MeanFD_Y2];

%% Compute residual correlations
rho_Y0Y2_reg1 = zeros(size(FC_final_Y0, 2), 2);


for counter = 1:size(FC_final_Y0, 2)
    FC_Y0 = FC_final_Y0(:, counter);
    FC_Y2 = FC_final_Y2(:, counter);

    % Regression model 1
    LM_Y0_r1 = fitlm(regressors_Y0_1, FC_Y0);
    LM_Y2_r1 = fitlm(regressors_Y2_1, FC_Y2);
    Y0_r1_resid = LM_Y0_r1.Residuals.Raw;
    Y2_r1_resid = LM_Y2_r1.Residuals.Raw;

    % Correlations
    [rho_r1, pval_r1] = corr(Y0_r1_resid, Y2_r1_resid, 'Type', 'Spearman');
  
    rho_Y0Y2_reg1(counter, :) = [rho_r1, pval_r1];
   
end

%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05,rho_Y0Y2_reg1(:,2));
%% Save results
save(save_path, 'rho_Y0Y2_reg1','fdr_index','-v7.3');

end
