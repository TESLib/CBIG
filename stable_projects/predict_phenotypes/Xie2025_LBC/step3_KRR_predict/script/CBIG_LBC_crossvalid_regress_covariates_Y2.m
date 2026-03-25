function [y_resid_perfold] = CBIG_LBC_crossvalid_regress_covariates_Y2( ...
    y0_csv, y2_csv, y_col_start, y_col_end, covmat_y0, covmat_y2, subfold_mat, outdir, outstem)
% [y_resid_perfold] = CBIG_LBC_crossvalid_regress_covariates_Y2(y0_csv, y2_csv,
%     y_col_start, y_col_end, covmat_y0, covmat_y2, subfold_mat, outdir, outstem)
%
% Cross-validated covariate regression for Year 2 behavioral data. For each
% test fold, regression coefficients are learned from Y0 training subjects
% and applied to Y2 test subjects to regress out covariates.
% Adapted from CBIG_crossvalid_regress_covariates_from_y by Jingwei Li and Ru(by) Kong.
%
% Input:
%     - y0_csv: (string)
%           Full path to the CSV file containing Y0 behavioral data.
%
%     - y2_csv: (string)
%           Full path to the CSV file containing Y2 behavioral data.
%
%     - y_col_start: (scalar or string)
%           First column index of behavioral variables in the CSV (e.g. 15).
%
%     - y_col_end: (scalar or string)
%           Last column index of behavioral variables in the CSV (e.g. 22).
%
%     - covmat_y0: (string)
%           Full path to Y0 covariate .mat file (variable: 'covariates').
%
%     - covmat_y2: (string)
%           Full path to Y2 covariate .mat file (variable: 'covariates').
%
%     - subfold_mat: (string)
%           Full path to cross-validation fold .mat file (variable: 'sub_fold').
%           sub_fold(i).fold_index is #subjects x 1: 1 = test, 0 = train.
%
%     - outdir: (string)
%           Full path of output directory. Subfolder [outdir]/y/fold_N created
%           for each test fold.
%
% Optional input:
%     - outstem: (string)
%           String appended to output filenames (e.g. 'cognition8').
%           Output saved as y_regress_<outstem>.mat; default is y_regress.mat.
%
% Output:
%     - y_resid_perfold: (cell array of length num_test_fold)
%           Each cell contains a #subjects x #measures residual matrix.
%           Also saved as .mat files under [outdir]/y/fold_N/.
%
% Example:
%     [resid] = CBIG_LBC_crossvalid_regress_covariates_Y2('Y0.csv', 'Y2.csv', ...
%         15, 22, 'cov_Y0.mat', 'cov_Y2.mat', 'subfold.mat', '/path/out', 'cognition8')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% convert string arguments if called from shell
if ischar(y_col_start); y_col_start = str2double(y_col_start); end
if ischar(y_col_end);   y_col_end   = str2double(y_col_end);   end

%% load inputs from file paths
Y0 = readtable(y0_csv);
y0_in = Y0{:, y_col_start:y_col_end};

Y2 = readtable(y2_csv);
y2_in = Y2{:, y_col_start:y_col_end};

tmp = load(covmat_y0);
y0_regressors = tmp.covariates;

tmp = load(covmat_y2);
y2_regressors = tmp.covariates;

tmp = load(subfold_mat);
sub_fold = tmp.sub_fold;

mkdir(outdir);

%% run cross-validated covariate regression
y_orig = y2_in;
num_test_folds = length(sub_fold);
for test_fold = 1:num_test_folds
    curr_outdir = fullfile(outdir, 'y', ['fold_' num2str(test_fold)]);
    mkdir(curr_outdir)
    if( exist('outstem', 'var') && ~isempty(outstem))
        outname = fullfile(curr_outdir, ['y_regress_' outstem '.mat']);
    else
        outname = fullfile(curr_outdir, ['y_regress.mat']);
    end

    if(~exist(outname, 'file'))
        if(ischar(y0_regressors) && strcmpi(y0_regressors, 'none'))
            y_resid = y_orig;
            beta = [];
        else
            beta = zeros(size(y0_regressors,2)+1, size(y0_in,2));
            for i = 1:size(y0_in, 2)
                train_ind = sub_fold(test_fold).fold_index==0;
                test_ind = sub_fold(test_fold).fold_index==1;

                if(isempty(y0_regressors))
                    X_train = [];
                    X_test = [];
                    X_train_mean = [];
                else
                    X_train = y0_regressors(train_ind,:);
                    X_train_mean = mean(X_train);
                    X_test = y2_regressors(test_ind,:);
                end

                [y_resid(train_ind,i), beta(:,i)] = ...
                    CBIG_regress_X_from_y_train(y0_in(train_ind,i), X_train);
                y_resid(test_ind,i) = ...
                    CBIG_regress_X_from_y_test(y2_in(test_ind,i), X_test, beta(:,i), X_train_mean);

                if(num_test_folds==1)
                    valid_ind = sub_fold(test_fold).fold_index==2;
                    if(isempty(y0_regressors))
                        X_valid = [];
                    else
                        X_valid = y2_regressors(valid_ind,:);
                    end
                    y_resid(valid_ind,i) = CBIG_regress_X_from_y_test(y2_in(valid_ind,i), X_valid, ...
                        beta(:,i), X_train_mean);
                end
            end
        end

        save(outname, 'y_resid', 'y_orig', 'beta');
    else
        fprintf('Already exist. Skipping ...\n')
        load(outname)
    end

    y_resid_perfold{test_fold} = y_resid;
    clear y_resid
end

end
