function CBIG_LBC_compute_cog_change_sex_effect(path_Y0, path_Y2, save_path)
% CBIG_LBC_compute_cog_change_sex_effect(path_Y0, path_Y2, save_path)
%
% Compute sex effect on cognitive change using a longitudinal mixed-effects
% model with a longAge x sex interaction term.
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
%     - A .mat file saved to save_path containing 't', 'p', 'b', 'se',
%       and 'fdr_index'. Each is (3 x 8): rows correspond to [male longAge,
%       sex interaction, female longAge (combined)]; columns to 8 measures.
%
% Example:
%     CBIG_LBC_compute_cog_change_sex_effect('DemoCog_Y0.csv', 'DemoCog_Y2.csv', 'sex_effect.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Read input
cog_measures_Y0 = readtable(path_Y0);
cog_measures_Y2 = readtable(path_Y2);
cog_measures_Y0.ageY0_centered = cog_measures_Y0.crossAge - mean(cog_measures_Y0.crossAge);
cog_measures_Y2.ageY0_centered = cog_measures_Y0.ageY0_centered;

% Concatenate data from Y0 and Y2
Data = [cog_measures_Y0(:,[1:14 27]); cog_measures_Y2(:,[1:14 27])];
DVars = [cog_measures_Y0(:,15:22); cog_measures_Y2(:,15:22)];

% Initialize output
p = zeros(3,8);
t = zeros(3,8);
b = zeros(3,8);
se = zeros(3,8);
% indices for 'longAge' and the interaction term.
i_age = [0   0   1   0   0];
i_int = [0   0   0   0   1];

% Create the contrast vector 'L' to specify the sum (longAge + sex_F:longAge)
L = i_age +i_int;

% Fit LME for each cognitive variable
for counter = 1:8
    Data.Dvar = DVars{:,counter};
    LME1 = fitlme(Data, 'Dvar ~ ageY0_centered + longAge*sex + (1 + longAge|src_subject_id)','FitMethod', 'REML');
    % LME2 = fitlme(Data, 'Dvar ~ ageY0_centered + longAge +sex + (1|src_subject_id)','FitMethod', 'REML');
    t(1:2,counter) = LME1.Coefficients.tStat([3 5]);
    p(1:2,counter) = LME1.Coefficients.pValue([3 5]);
    b(1:2,counter) = LME1.Coefficients.Estimate([3 5]);
    se(1:2,counter) = LME1.Coefficients.SE([3 5]);
    % calcuate female longAge statistic
    % 1. Get the coefficient estimates and covariance from the fitted model
    
    beta_estimates = LME1.Coefficients.Estimate;
    covB  = LME1.CoefficientCovariance;  % covariance of fixed-effect estimates
    
    % 2. Use coefTest to get the p-value hypothesis L*beta=0
    [p_val, F] = coefTest(LME1, L, 0);
    
    % 3. Calculate the combined estimate and the corresponding t-statistic
    b_female = L * beta_estimates; % This is (longAge+sex_F:longAge)
    
    % SE for female slope (delta method)
    se_female = sqrt(L * covB * L');
    
    % t statistic for the linear combination
    t_female = b_female / se_female;
    
    % 4. Store the results for this iteration
    t(3, counter) = t_female;
    p(3, counter) = p_val;
    b(3, counter)= b_female;
    se(3,counter) = se_female;
end
%% FDR
fdr_index = CBIG_LBC_run_FDR(0.05, p(1,:),p(2,:),p(3,:));
% Save results
save(save_path, 't', 'p','b','se','fdr_index');

end
