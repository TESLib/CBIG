function CBIG_LBC_KRR_check_example_results(out_dir)

% CBIG_LBC_check_KRR_example_results(out_dir)
% This function checks if the generated example results are identical to
% the reference files.
%
% Input:
%   - out_dir
%     The output directory path saving results of example scripts
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% get directories
ref_dir = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', ...
    'Xie2025_LBC', 'examples', 'ref_results');

% compare prediction accuracies of KRR
ref_acc = load(fullfile(ref_dir, 'final_result_2cog.mat'));
test_acc = load(fullfile(out_dir, 'final_result_2cog.mat'));

diff_acc = max(max(abs(ref_acc.optimal_acc - test_acc.optimal_acc)));
assert(diff_acc< 1e-5, sprintf('Difference in acc of KRR of: %f', diff_acc));

display('Xie2025_LBC KRR example run successfully!')

end
