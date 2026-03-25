function CBIG_LBC_ABCD_PNF_compare(PNF_networkBlock_file_model1, PNF_networkBlock_file_model2, ...
    PNF_standard_file_model1, PNF_standard_file_model2, output_file)
% CBIG_LBC_ABCD_PNF_compare(PNF_networkBlock_file_model1, PNF_networkBlock_file_model2,
%     PNF_standard_file_model1, PNF_standard_file_model2, output_file)
%
% Compare sign consistency of predictive network features (PNFs) between two KRR
% models. Identifies network blocks (18x18) with consistent or inconsistent signs,
% then maps those patterns to parcel-level (419x419) matrices. All PNFs are
% z-scored before comparison.
%
% Input:
%     - PNF_networkBlock_file_model1: (string)
%           Path to network-block-level PNF for model 1 (.mat, variable:
%           PNF_measure_n_NetworkBlock, size 18x18).
%
%     - PNF_networkBlock_file_model2: (string)
%           Path to network-block-level PNF for model 2 (.mat, same variable).
%
%     - PNF_standard_file_model1: (string)
%           Path to parcel-level PNF for model 1 (.mat, variable:
%           PNF_measure_n_standard, size 87571 x 1).
%
%     - PNF_standard_file_model2: (string)
%           Path to parcel-level PNF for model 2 (.mat, same variable).
%
%     - output_file: (string)
%           Full path to save all output matrices (.mat).
%
% Output:
%     - A .mat file saved to output_file containing:
%         PNF_model1_block_SignConsist, PNF_model2_block_SignConsist (18x18),
%         PNF_model1_block_SignInconsist, PNF_model2_block_SignInconsist (18x18),
%         PNF_measure_n_standard_model1_SignConsist, ..._SignInConsist (419x419),
%         PNF_measure_n_standard_model2_SignConsist, ..._SignInConsist (419x419).
%
% Example:
%     CBIG_LBC_ABCD_PNF_compare('PNF_block_Y0.mat', 'PNF_block_Y2.mat', ...
%         'PNF_std_Y0.mat', 'PNF_std_Y2.mat', 'PNF_compare.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');

load(fullfile(repo_root,'util','Yan_400label','NetworkIndex_YanKong17.mat'),'Index','NetworkRange_minor')
 
load(PNF_networkBlock_file_model1)
PNF_model1 = PNF_measure_n_NetworkBlock;
PNF_model1 = PNF_model1./std(PNF_model1(:));

load(PNF_networkBlock_file_model2)
PNF_model2 = PNF_measure_n_NetworkBlock;
PNF_model2 = PNF_model2./std(PNF_model2(:));



% SigMask_model1 = p_model1;
% sum(SigMask_model1)
% p_model2(p_model2>pID) = 0;
% p_model2(p_model2~=0) = 1;
% SigMask_model2 = p_model2;
% sum(SigMask_model2)
% ConsistantSig = SigMask_model2+SigMask_model1;
% ConsistantSigMask = (ConsistantSig==2);

SignConsist = (PNF_model1.*PNF_model2>0);
WholeMask = ones(171,1);
SignInconsist = WholeMask-SignConsist;
sum(SignConsist)
sum(SignInconsist)


%%
% transform block sig index into full matrix
M = zeros(18);
M(tril(true(18))) = SignConsist;
SignConsist_Full = M + triu(M', 1);

M = zeros(18);
M(tril(true(18))) = SignInconsist;
SignInconsist_Full = M + triu(M', 1);
%% extract consist and inconsit block
PNF_model1_block = zeros(18);
mask = tril(true(18));
PNF_model1_block(mask) = PNF_model1(:);

PNF_model2_block = zeros(18);
mask = tril(true(18));
PNF_model2_block(mask) = PNF_model2(:);

PNF_model1_block_SignConsist = PNF_model1_block.*SignConsist_Full;
PNF_model1_block_SignInconsist = PNF_model1_block.*SignInconsist_Full;
PNF_model1_block_SignConsist = PNF_model1_block_SignConsist + ...
    PNF_model1_block_SignConsist' - diag(diag(PNF_model1_block_SignConsist));
PNF_model1_block_SignInconsist = PNF_model1_block_SignInconsist + ...
    PNF_model1_block_SignInconsist' - diag(diag(PNF_model1_block_SignInconsist));

PNF_model2_block_SignConsist = PNF_model2_block.*SignConsist_Full;
PNF_model2_block_SignInconsist = PNF_model2_block.*SignInconsist_Full;
PNF_model2_block_SignConsist = PNF_model2_block_SignConsist + ...
    PNF_model2_block_SignConsist' - diag(diag(PNF_model2_block_SignConsist));
PNF_model2_block_SignInconsist = PNF_model2_block_SignInconsist + ...
    PNF_model2_block_SignInconsist' - diag(diag(PNF_model2_block_SignInconsist));

%%
%transform the network block into roixroi

SignConsist_419Mask = zeros(419);
SignInconsist_419Mask = zeros(419);

for i = 1:length(NetworkRange_minor)
    for j = 1:length(NetworkRange_minor)
        SignConsist_419Mask(NetworkRange_minor{i},NetworkRange_minor{j}) = SignConsist_Full(i,j);
        
        SignInconsist_419Mask(NetworkRange_minor{i},NetworkRange_minor{j}) = SignInconsist_Full(i,j);
        
    end
end

load(PNF_standard_file_model1)
PNF_measure_n_standard_model1 = PNF_measure_n_standard;

load(PNF_standard_file_model2)
PNF_measure_n_standard_model2 = PNF_measure_n_standard;

PNF_measure_n_standard_model1 = squareform(PNF_measure_n_standard_model1);
PNF_measure_n_standard_model1 = PNF_measure_n_standard_model1(Index,Index);
PNF_measure_n_standard_model2 = squareform(PNF_measure_n_standard_model2);
PNF_measure_n_standard_model2 = PNF_measure_n_standard_model2(Index,Index);


PNF_measure_n_standard_model1_SignConsist = PNF_measure_n_standard_model1.*SignConsist_419Mask;
PNF_measure_n_standard_model1_SignInConsist = PNF_measure_n_standard_model1.*SignInconsist_419Mask;
PNF_measure_n_standard_model2_SignConsist = PNF_measure_n_standard_model2.*SignConsist_419Mask;
PNF_measure_n_standard_model2_SignInConsist = PNF_measure_n_standard_model2.*SignInconsist_419Mask;

[~, invIndex] = sort(Index);

PNF_measure_n_standard_model1_SignConsist = PNF_measure_n_standard_model1_SignConsist(invIndex,invIndex);
PNF_measure_n_standard_model1_SignInConsist = PNF_measure_n_standard_model1_SignInConsist(invIndex,invIndex);
PNF_measure_n_standard_model2_SignConsist = PNF_measure_n_standard_model2_SignConsist(invIndex,invIndex);
PNF_measure_n_standard_model2_SignInConsist = PNF_measure_n_standard_model2_SignInConsist(invIndex,invIndex);

save(output_file, 'PNF_model1_block_SignConsist', 'PNF_model2_block_SignConsist', ...
    'PNF_model1_block_SignInconsist', 'PNF_model2_block_SignInconsist', ...
    'PNF_measure_n_standard_model1_SignConsist', 'PNF_measure_n_standard_model1_SignInConsist', ...
    'PNF_measure_n_standard_model2_SignConsist', 'PNF_measure_n_standard_model2_SignInConsist')
end
