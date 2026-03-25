function [p_value,meanAcc_true] = CBIG_LBC_compute_permP(PermFolder,InputFile,OutputFile)

% CBIG_LBC_compute_permP
%
% Compute permutation-based p-values for prediction accuracies across 8 cognitive scores.
%
% This function compares the true prediction accuracy against null distributions
% generated from permutation tests. For each cognitive score, it calculates
% a p-value as the proportion of permutations with accuracy greater than the
% true accuracy, using a (1 + N_worse) / (1 + Nperm) formulation.
%
% INPUTS:
%   - PermFolder: path to the folder containing permutation accuracy results
%                 (e.g., '.../permutation_results/')
%   - InputFile: path to the .mat file containing variable 'optimal_acc',
%                the Fisher-z transformed accuracies for the true model
%   - OutputFile: path to save the output .mat file containing p-values and true accuracy
%
% OUTPUTS:
%   - p_value: 8x1 vector of permutation p-values for each cognitive score
%   - meanAcc_true: 8x1 vector of mean true accuracies (after tanh transformation)
%
% Example usage:
%   [p, acc] = CBIG_LBC_compute_permP('perms/', 'true_acc.mat', 'pvals.mat');
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

p_value = zeros(8,1);

load(InputFile)
meanAcc_true = tanh(mean(CBIG_StableAtanh(optimal_acc)));
max(meanAcc_true)
for score_indx = 1:8
    load([PermFolder,'acc_score',num2str(score_indx),'_allFolds_permStart1.mat'])
    Nperm = size(stats_perm.corr,2);
    % load reference
    ref = meanAcc_true(score_indx);
    % load permutations
    curr_acc = mean(stats_perm.corr,1);
    N_worse = sum(curr_acc > ref);

    p_value(score_indx,1) = (1+N_worse)/(1+Nperm);
    
end

save(OutputFile,'p_value','meanAcc_true');