function CBIG_LBC_ABCD_PNF_block(cov_mat_true_file, measureIndex, output_PNF_standard, output_PNF_networkBlock)
% CBIG_LBC_ABCD_PNF_block(cov_mat_true_file, measureIndex, output_PNF_standard, output_PNF_networkBlock)
%
% Compute standardized predictive network features (PNF) from KRR covariance
% matrices and extract both parcel-level and network-block-level feature maps.
%
% Input:
%     - cov_mat_true_file: (string)
%           Full path to a .mat file containing a 3D covariance matrix of size
%           419 x 419 x 8 (variable: cov_mat).
%
%     - measureIndex: (scalar)
%           Index (1–8) indicating which cognitive measure's PNF to extract.
%
%     - output_PNF_standard: (string)
%           Full path to save the parcel-wise standardized PNF vector (.mat,
%           variable: PNF_measure_n_standard, size 87571 x 1).
%
%     - output_PNF_networkBlock: (string)
%           Full path to save the network-block-level PNF matrix (.mat,
%           variable: PNF_measure_n_NetworkBlock, size 18 x 18).
%
% Output:
%     - .mat files saved to output_PNF_standard and output_PNF_networkBlock.
%
% Example:
%     CBIG_LBC_ABCD_PNF_block('cov_mat.mat', 1, 'PNF_standard_1.mat', 'PNF_block_1.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
  
addpath(genpath(fullfile(repo_root,'util','stats','network')));
load(cov_mat_true_file);
cov_mat = cov_mat(:,:,1:8);
PNF_mean1 = mean(cov_mat,1);
PNF_mean1 = squeeze(PNF_mean1);
PNF_measure_n = PNF_mean1(:,measureIndex);


%Measure n
min(PNF_measure_n(:))
max(PNF_measure_n(:))
PNF_measure_n_standard = PNF_measure_n./std(PNF_measure_n(:));
PNF_measure_n_NetworkBlock = CBIG_LBC_ABCD_compute_average_minor_network(PNF_measure_n,1);

save(output_PNF_standard,'PNF_measure_n_standard');
save(output_PNF_networkBlock,'PNF_measure_n_NetworkBlock');
rmpath(genpath(fullfile(repo_root,'util','stats','network')));
end

