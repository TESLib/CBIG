function CBIG_LBC_PNF_standard_per_sex(measureIndex, colorbar_min, colorbar_max)
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
% CBIG_LBC_PNF_standard_per_sex(measureIndex, colorbar_min, colorbar_max)
%
% Plot standardized PNF (predictive network features) network matrices for
% each of four KRR models (FC_Y0->CogY0, FCY0->CogY2, FC_Y2->CogY2,
% FC_Delta->CogDelta) separately for male and female subjects.
%
% Input:
%     - measureIndex: (scalar)
%           Index (1-8) indicating which cognitive measure's PNF to plot.
%
%     - colorbar_min: (scalar)
%           Minimum value for the color scale.
%
%     - colorbar_max: (scalar)
%           Maximum value for the color scale.
%
% Output:
%     - Eight .tif network matrix figures (4 models x 2 sexes) saved to
%       the sex-stratified PNF output directory.
%
% Example:
%     CBIG_LBC_PNF_standard_per_sex(2, -1.2, 1.2)


repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
addpath(genpath(fullfile(repo_root)));

%% load PNF
% male
load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y0_male/interpretation/FC_final_Y0_male/cov_mat.mat']);
FC_Y0_male = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FCY0CogY2_male/interpretation/FC_final_Y0_male/cov_mat.mat']);
FCY0CogY2_male = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y2_male/interpretation/FC_final_Y2_male/cov_mat.mat']);
FC_Y2_male = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Delta_CogDelta_male/interpretation/Delta_FC_male/cov_mat.mat']);
FC_Delta_CogDelta_male = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

% female
load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y0_female/interpretation/FC_final_Y0_female/cov_mat.mat']);
FC_Y0_female = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FCY0CogY2_female/interpretation/FC_final_Y0_female/cov_mat.mat']);
FCY0CogY2_female = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y2_female/interpretation/FC_final_Y2_female/cov_mat.mat']);
FC_Y2_female = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Delta_CogDelta_female/interpretation/Delta_FC_female/cov_mat.mat']);
FC_Delta_CogDelta_female = cov_mat(:,:,measureIndex)./repmat(std(cov_mat(:,:,measureIndex),0,2),1,size(cov_mat,2));

%% plot PNF for each model and each sex
colors = [0, 230, 255
0, 0, 255
0,0,0
255, 0, 0
255, 255, 0]/255;

% colorbar_min = -1.2
% colorbar_max = 1.2
% male
outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Y0_male.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Y0_male),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY0CogY2_male.tif');
CBIG_LBC_plot_network_matrix(mean(FCY0CogY2_male),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Y2_male.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Y2_male),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Delta_CogDelta_male.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Delta_CogDelta_male),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);


% female
outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Y0_female.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Y0_female),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY0CogY2_female.tif');
CBIG_LBC_plot_network_matrix(mean(FCY0CogY2_female),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Y2_female.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Y2_female),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FC_Delta_CogDelta_female.tif');
CBIG_LBC_plot_network_matrix(mean(FC_Delta_CogDelta_female),colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

rmpath(genpath(fullfile(repo_root)));

end

