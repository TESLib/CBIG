function CBIG_LBC_PNF_sex_diff_block(measureIndex,colorbar_min,colorbar_max)
% CBIG_LBC_PNF_sex_diff
% 
% plot PNF sex difference for each model 
%
%
% INPUTS:
%   - measureIndex: a scalar indicates which measure to use. 
%   - colorbar_min/colorbar_max: the range of the colorbar used for the plot 
%
% OUTPUTS:heatmap for each model and each sex
%
% Example umeasureIndexsage:
%   CBIG_LBC_PNF_sex_diff(8,-5,5)
 
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
 addpath(genpath(fullfile(repo_root)));
%% load PNF
% male
load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y0_male/interpretation/FC_final_Y0_male/cov_mat.mat']);
FC_Y0_male = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FCY0CogY2_male/interpretation/FC_final_Y0_male/cov_mat.mat']);
FCY0CogY2_male = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y2_male/interpretation/FC_final_Y2_male/cov_mat.mat']);
FC_Y2_male = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Delta_CogDelta_male/interpretation/Delta_FC_male/cov_mat.mat']);
FC_Delta_CogDelta_male = cov_mat(:,:,measureIndex);

FCY2_FCY0_diff_male = FC_Y2_male - FC_Y0_male;

% female
load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y0_female/interpretation/FC_final_Y0_female/cov_mat.mat']);
FC_Y0_female = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FCY0CogY2_female/interpretation/FC_final_Y0_female/cov_mat.mat']);
FCY0CogY2_female = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Y2_female/interpretation/FC_final_Y2_female/cov_mat.mat']);
FC_Y2_female = cov_mat(:,:,measureIndex);

load(['/home/yxie/storage/Xie_Code/ABCD/Response/sex/KRR_results/' ...
    'FC_Delta_CogDelta_female/interpretation/Delta_FC_female/cov_mat.mat']);
FC_Delta_CogDelta_female = cov_mat(:,:,measureIndex);

FCY2_FCY0_diff_female = FC_Y2_female - FC_Y0_female;

FCY2_FCY0_diff_female_block = zeros(120,171);
FC_Y0_female_block = zeros(120,171);
FCY0CogY2_female_block = zeros(120,171);
FC_Y2_female_block = zeros(120,171);
FC_Delta_CogDelta_female_block = zeros(120,171);

FCY2_FCY0_diff_male_block = zeros(120,171);
FC_Y0_male_block = zeros(120,171);
FCY0CogY2_male_block = zeros(120,171);
FC_Y2_male_block = zeros(120,171);
FC_Delta_CogDelta_male_block = zeros(120,171);
% standardize for each fold across sex
for n_fold = 1:120
    % diff
    sd_f = sqrt( (std(FC_Y0_male(n_fold,:))^2 + std(FC_Y0_female(n_fold,:))^2 + ...
        std(FC_Y2_male(n_fold,:))^2 + std(FC_Y2_female(n_fold,:))^2)/4 );
    FCY2_FCY0_diff_female(n_fold,:) = FCY2_FCY0_diff_female(n_fold,:)./sd_f;
    FCY2_FCY0_diff_male(n_fold,:) = FCY2_FCY0_diff_male(n_fold,:)./sd_f;
    FCY2_FCY0_diff_female_block(n_fold,:) = ...
        CBIG_LBC_ABCD_compute_average_minor_network(FCY2_FCY0_diff_female(n_fold,:), 1);
    FCY2_FCY0_diff_male_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FCY2_FCY0_diff_male(n_fold,:), 1);

    % FC_Y0
    sd_f = sqrt( (std(FC_Y0_male(n_fold,:))^2 + std(FC_Y0_female(n_fold,:))^2)/2 ); 
    FC_Y0_male(n_fold,:) = FC_Y0_male(n_fold,:)./sd_f;
    FC_Y0_female(n_fold,:) = FC_Y0_female(n_fold,:)./sd_f;
    FC_Y0_female_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FC_Y0_female(n_fold,:), 1);
    FC_Y0_male_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FC_Y0_male(n_fold,:), 1);

    % FCY0CogY2
    sd_f = sqrt( (std(FCY0CogY2_male(n_fold,:))^2 + std(FCY0CogY2_female(n_fold,:))^2)/2 ); 
    FCY0CogY2_male(n_fold,:) = FCY0CogY2_male(n_fold,:)./sd_f;
    FCY0CogY2_female(n_fold,:) = FCY0CogY2_female(n_fold,:)./sd_f;
    FCY0CogY2_female_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FCY0CogY2_female(n_fold,:), 1);
    FCY0CogY2_male_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FCY0CogY2_male(n_fold,:), 1);

    % FC_Y2
    sd_f = sqrt( (std(FC_Y2_male(n_fold,:))^2 + std(FC_Y2_female(n_fold,:))^2)/2 ); 
    FC_Y2_male(n_fold,:) = FC_Y2_male(n_fold,:)./sd_f;
    FC_Y2_female(n_fold,:) = FC_Y2_female(n_fold,:)./sd_f;
    FC_Y2_female_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FC_Y2_female(n_fold,:), 1);
    FC_Y2_male_block(n_fold,:) = CBIG_LBC_ABCD_compute_average_minor_network(FC_Y2_male(n_fold,:), 1);

    % FC_Delta_CogDelta
    sd_f = sqrt( (std(FC_Delta_CogDelta_male(n_fold,:))^2 + std(FC_Delta_CogDelta_female(n_fold,:))^2)/2 ); 
    FC_Delta_CogDelta_male(n_fold,:) = FC_Delta_CogDelta_male(n_fold,:)./sd_f;
    FC_Delta_CogDelta_female(n_fold,:) = FC_Delta_CogDelta_female(n_fold,:)./sd_f; 
    FC_Delta_CogDelta_female_block(n_fold,:) = ...
        CBIG_LBC_ABCD_compute_average_minor_network(FC_Delta_CogDelta_female(n_fold,:), 1);
    FC_Delta_CogDelta_male_block(n_fold,:) = ...
        CBIG_LBC_ABCD_compute_average_minor_network(FC_Delta_CogDelta_male(n_fold,:), 1);
    
    
end

    

%%  correct resample t test for the PNF sex difference for each edge
PNF_FCY0_ttest = zeros(size(FC_Y0_male_block,2),2);
PNF_FCY0CogY2_ttest = zeros(size(FC_Y0_male_block,2),2);
PNF_FCY2_ttest = zeros(size(FC_Y0_male_block,2),2);
PNF_Delta_ttest = zeros(size(FC_Y0_male_block,2),2); 
PNF_Y2Y0_diff_ttest = zeros(size(FC_Y0_male_block,2),2); 
for n_block = 1:size(FC_Y0_male_block,2)
    n_block
[tval,p] = CBIG_LBC_corrected_resampled_ttest((FC_Y0_female_block(:,n_block)-FC_Y0_male_block(:,n_block)),3/7,0);
PNF_FCY0_ttest(n_block,:) = [tval,p];

[tval,p] = CBIG_LBC_corrected_resampled_ttest((FCY0CogY2_female_block(:,n_block) - ...
    FCY0CogY2_male_block(:,n_block)),3/7,0);
PNF_FCY0CogY2_ttest(n_block,:) = [tval,p];

[tval,p] = CBIG_LBC_corrected_resampled_ttest((FC_Y2_female_block(:,n_block)-FC_Y2_male_block(:,n_block)),3/7,0);
PNF_FCY2_ttest(n_block,:) = [tval,p];

[tval,p] = CBIG_LBC_corrected_resampled_ttest((FC_Delta_CogDelta_female_block(:,n_block) - ...
    FC_Delta_CogDelta_male_block(:,n_block)),3/7,0);
PNF_Delta_ttest(n_block,:) = [tval,p];

[tval,p] = CBIG_LBC_corrected_resampled_ttest((FCY2_FCY0_diff_female_block(:,n_block) - ...
    FCY2_FCY0_diff_male_block(:,n_block)),3/7,0);
PNF_Y2Y0_diff_ttest(n_block,:) = [tval,p];


end

%% FDR on the resample t test p 
[FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, PNF_FCY0_ttest(:,2));
PNF_FCY0_sig_indx = zeros(171,1);
PNF_FCY0_sig_indx(FDR_sig_idx_sets{1,1}) = 1;
PNF_FCY0_sig_t = PNF_FCY0_ttest(:,1).*PNF_FCY0_sig_indx;
min(PNF_FCY0_sig_t) %-17
max(PNF_FCY0_sig_t)


[FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, PNF_FCY0CogY2_ttest(:,2));
PNF_FCY0CogY2_sig_indx = zeros(171,1);
PNF_FCY0CogY2_sig_indx(FDR_sig_idx_sets{1,1}) = 1;
PNF_FCY0CogY2_sig_t = PNF_FCY0CogY2_ttest(:,1).*PNF_FCY0CogY2_sig_indx;
min(PNF_FCY0CogY2_sig_t) %-15
max(PNF_FCY0CogY2_sig_t)

[FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, PNF_FCY2_ttest(:,2));
PNF_FCY2_sig_indx = zeros(171,1);
PNF_FCY2_sig_indx(FDR_sig_idx_sets{1,1}) = 1;
PNF_FCY2_sig_t = PNF_FCY2_ttest(:,1).*PNF_FCY2_sig_indx;
min(PNF_FCY2_sig_t) %-14
max(PNF_FCY2_sig_t)

[FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, PNF_Delta_ttest(:,2));
PNF_Delta_sig_indx = zeros(171,1);
PNF_Delta_sig_indx(FDR_sig_idx_sets{1,1}) = 1;
PNF_Delta_sig_t = PNF_Delta_ttest(:,1).*PNF_Delta_sig_indx;
min(PNF_Delta_sig_t) %-15
max(PNF_Delta_sig_t)

[FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, PNF_Y2Y0_diff_ttest(:,2));
PNF_Y2Y0_diff_sig_indx = zeros(171,1);
PNF_Y2Y0_diff_sig_indx(FDR_sig_idx_sets{1,1}) = 1;
PNF_Y2Y0_diff_sig_t = PNF_Y2Y0_diff_ttest(:,1).*PNF_Y2Y0_diff_sig_indx;
min(PNF_Y2Y0_diff_sig_t) %-15
max(PNF_Y2Y0_diff_sig_t)
%% write the 18x18 in 419x419 matix, each block have same value
PNF_FCY0_sig_t = CBIG_LBC_block_fullmatrix(PNF_FCY0_sig_t);
PNF_FCY0CogY2_sig_t = CBIG_LBC_block_fullmatrix(PNF_FCY0CogY2_sig_t);
PNF_FCY2_sig_t = CBIG_LBC_block_fullmatrix(PNF_FCY2_sig_t);
PNF_Delta_sig_t = CBIG_LBC_block_fullmatrix(PNF_Delta_sig_t);
PNF_Y2Y0_diff_sig_t = CBIG_LBC_block_fullmatrix(PNF_Y2Y0_diff_sig_t);

%% plot PNF for each model and each sex
colors = [0, 230, 255
0, 0, 255
0,0,0
255, 0, 0
255, 255, 0]/255;

% colorbar_min = -5
% colorbar_max = 5
matrices = {PNF_FCY0_sig_t, PNF_FCY0CogY2_sig_t, PNF_FCY2_sig_t, PNF_Delta_sig_t, PNF_Y2Y0_diff_sig_t};
for i = 1:numel(matrices)
    M = matrices{i};
    M(1:size(M,1)+1:end) = 0;
    M(isnan(M)) = 0;
    matrices{i} = squareform(M);
end
[PNF_FCY0_sig_t, PNF_FCY0CogY2_sig_t, PNF_FCY2_sig_t, PNF_Delta_sig_t, PNF_Y2Y0_diff_sig_t] = matrices{:};
outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY0_sig_sex_diff_block.tif');
mkdir(fileparts(outputfile))
CBIG_LBC_plot_network_matrix(PNF_FCY0_sig_t,colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

clim = [colorbar_min,colorbar_max];
size_cm = [0.6, 4.5];
orientation = 'vertical';
cb_position = [0.3, 0.1, 0.4, 0.8];
filename = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY0_sig_sex_diff_colorbar_block.pdf');
CBIG_LBC_draw_colorbar(colors, clim, size_cm, filename, orientation, cb_position)

%%
outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY0CogY2_sig_sex_diff_block.tif');
CBIG_LBC_plot_network_matrix(PNF_FCY0CogY2_sig_t,colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY2_sig_sex_diff_block.tif');
CBIG_LBC_plot_network_matrix(PNF_FCY2_sig_t,colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCDelta_sig_sex_diff_block.tif');
CBIG_LBC_plot_network_matrix(PNF_Delta_sig_t,colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

outputfile = fullfile(getenv('LBC_rep_dir'), 'Results', 'PNF', 'sex', ...
    ['measure_', num2str(measureIndex)], 'FCY2Y0_diff_sig_sex_diff_block.tif');
CBIG_LBC_plot_network_matrix(PNF_Y2Y0_diff_sig_t,colors,colorbar_min,colorbar_max, outputfile, 300,5,4.8);

rmpath(genpath(fullfile(repo_root)));

end