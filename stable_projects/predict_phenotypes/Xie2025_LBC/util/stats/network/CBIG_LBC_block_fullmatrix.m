function block_vec_419 = CBIG_LBC_block_fullmatrix(block_vec)
% CBIG_LBC_block_fullmatrix
%
% make the block level vector into 419x419 matrix, each block in the full
% matrix has same value
%
%
% INPUTS:
%   - block_vec: a vector from the low triangle of the 18x18 matrix
%
% OUTPUTS:
%   - block_vec_419: a 419x419 matrix, where each network block have same
%   value.
%
% Example usage:
%   CBIG_LBC_PNF_sex_diff(8,-5,5)

% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md


repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
addpath(genpath(fullfile(repo_root)));

M = zeros(18);
M(tril(true(18))) = block_vec;
block_vec_Full = M + triu(M', 1);
min(block_vec)
max(block_vec)

load(fullfile(repo_root,'util','Yan_400label','NetworkIndex_YanKong17.mat'),'Index','NetworkRange_minor')

block_vec_419 = zeros(419);
for i = 1:length(NetworkRange_minor)
    for j = 1:length(NetworkRange_minor)
        block_vec_419(NetworkRange_minor{i},NetworkRange_minor{j}) = block_vec_Full(i,j);
    end
end

[~, invIndex] = sort(Index);
block_vec_419 = block_vec_419(invIndex,invIndex);
rmpath(genpath(fullfile(repo_root)));
end