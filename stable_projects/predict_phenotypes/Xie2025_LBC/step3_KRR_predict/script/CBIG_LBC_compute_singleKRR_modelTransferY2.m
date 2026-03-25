function CBIG_LBC_compute_singleKRR_modelTransferY2(singleKRR_dir_y0, FC_Y0, FC_Y2, ...
    y2_resid_dir, outstem_y0, score_ind, ...
    site_list, outdir, perm_seed_start, N_perm)
% CBIG_LBC_compute_singleKRR_modelTransferY2(singleKRR_dir_y0, FC_Y0, FC_Y2,
%     y2_resid_dir, outstem_y0, score_ind, site_list, outdir, perm_seed_start, N_perm)
%
% Transfer a baseline (Y0) KRR model to Year 2 data and compute prediction
% accuracy with permutation testing. For each test fold, the Y0 model
% parameters are applied to Y2 FC to predict Y2 cognitive scores.
%
% Input:
%     - singleKRR_dir_y0: (string)
%           Directory containing singleKRR results for FCY0->CogY0.
%
%     - FC_Y0: (string)
%           Full path to .mat file containing FC matrix for Year 0
%           (variable: FC_final_Y0, size #features x #subjects).
%
%     - FC_Y2: (string)
%           Full path to .mat file containing FC matrix for Year 2
%           (variable: FC_final_Y2, same subject order as FC_Y0).
%
%     - y2_resid_dir: (string)
%           Directory containing regressed Y2 results from
%           CBIG_LBC_crossvalid_regress_covariates_Y2.
%
%     - outstem_y0: (string)
%           Stem string used in the Y0 KRR output filenames.
%
%     - score_ind: (scalar)
%           Index of the target variable to test (1 to #measures).
%
%     - site_list: (string)
%           Full path to a CSV file with a SiteCluster column (one row per subject).
%           Permutations are performed within sites.
%
%     - outdir: (string)
%           Output directory for permutation results.
%
%     - perm_seed_start: (scalar)
%           Starting permutation seed. N_perm seeds from perm_seed_start
%           to perm_seed_start+N_perm-1 will be used.
%
%     - N_perm: (scalar)
%           Number of permutations.
%
% Output:
%     - A .mat file saved to outdir containing 'pred_stats_true', 'loss_true',
%       and 'stats_perm'.
%
% Example:
%     CBIG_LBC_compute_singleKRR_modelTransferY2('/path/KRR_FC_Y0', 'FC_Y0.mat', ...
%         'FC_Y2.mat', '/path/y2_resid', 'cognition8', 1, 'site.csv', '/path/out', 1, 1000)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% check if output already exist
result_file = fullfile(outdir,['/acc_score' num2str(score_ind) '_allFolds_permStart' num2str(perm_seed_start) '.mat']);

if ~exist(result_file,'file')
    %% check input arguments
    if(isstr(score_ind))
        score_ind = str2num(score_ind);
    end
    
    if ~exist(outdir,'dir')
        mkdir(outdir);
    end
    
    %% load site ID
    sub_table = readtable(site_list);
    site_all = sub_table.SiteCluster; 
    [~, ~, site_ind] = unique(site_all);
    N_site = max(site_ind);
    
    %% load cross-validation split
    sub_fold_file = dir(fullfile(singleKRR_dir_y0,'..','*sub_list.mat'));
    if length(sub_fold_file) ~= 1
        error('There should be one and only one sub_fold file in the singleKRR directory');
    end
    load(fullfile(singleKRR_dir_y0,'..',sub_fold_file.name));
    N_fold = length(sub_fold);
    %% load FC_Y0 and FC_Y2 for computating FSM_pred for each fold
     load(FC_Y0);
     load(FC_Y2);
    %% perform the model transfer for y2 accuracy and permutation test
    metrics = {'corr','COD','predictive_COD','MAE','MAE_norm','MSE','MSE_norm'};
    for i = 1:length(metrics)
        stats_perm.(metrics{i}) = zeros(N_fold,N_perm);
    end
    
    load(fullfile(singleKRR_dir_y0, 'results', ['final_result_' outstem_y0 '.mat']));
    for i = 1:N_fold
        disp(['fold ' num2str(i)]);
        % load data
        load(fullfile(singleKRR_dir_y0,'results','y', ['fold_' num2str(i)], ['y_regress_' outstem_y0 '.mat']));
        y_resid_y0 = y_resid(:,score_ind);
        
        load(fullfile(y2_resid_dir,'y', ['fold_' num2str(i)], 'y_regress_cognition8.mat'));
        y_resid_y2 = y_resid(:,score_ind);
        
        opt_lambda = optimal_lambda(i,score_ind);
        test_ind = sub_fold(i).fold_index;
        train_ind = ~test_ind;
        
        load(fullfile(singleKRR_dir_y0,'results','FSM_test',['fold_' num2str(i)], 'FSM_corr.mat'));
        FSM_train = FSM(train_ind,train_ind,:);
        % compute FSM_pred, which is the FC similarity between test and training subject
    % main results
        train_sub_FC = FC_final_Y0(:,train_ind);
        test_sub_FC = FC_final_Y2(:,test_ind);

        % validation for motion
        %train_sub_FC = FC_Y0_MotionControl(:,train_ind);
        %test_sub_FC = FC_Y2_MotionControl(:,test_ind);
      
        FSM_pred = corr(test_sub_FC,train_sub_FC);
        
        % number of subjects
        num_train_subj = size(FSM_train,1);
        num_test_subj = size(FSM_pred,1);
        
        % Perform model transfer: apply parameter of baseline to 2-year follow-up FCY0->CogY0 to FCY2->CogY2
        K_r = FSM_train + opt_lambda*eye(num_train_subj);
        % training
        X = ones(num_train_subj,1);
        inv_K_r = inv(K_r);
        beta_pre = (X' * (inv_K_r * X)) \ X' * inv_K_r;
        y_train_resid = y_resid_y0(train_ind);
        y_test_resid = y_resid_y2(test_ind);
        beta = beta_pre * y_train_resid;
        alpha = inv_K_r * (y_train_resid - X * beta);
        y_predicted = FSM_pred * alpha + ones(num_test_subj,1) .* beta;
         
        for metrics_index = 1:length(metrics)
            [pred_stats,loss] = CBIG_compute_prediction_acc_and_loss(y_predicted,y_test_resid, ...
                metrics{metrics_index},y_train_resid);
            pred_stats_true(i,metrics_index) = pred_stats;
            loss_true(i,metrics_index) = loss;
        end
       
        % permutation test for the significance of the transfered accuracy
        for j = 1:N_perm
            % permute behavior within site
            rng(j+perm_seed_start-1);
            y_perm_y0 = y_resid_y0;
            y_perm_y2 = y_resid_y2;
            
            for k = 1:N_site
                
                % Generate the permutation index for the current site
                perm_idx = randperm(sum(site_ind == k));
                
                % Apply the same permutation to both y_perm_y0 and y_perm_y2
                y_tmp_y0 = y_perm_y0(site_ind == k);
                y_perm_y0(site_ind == k) = y_tmp_y0(perm_idx);
                
                y_tmp_y2 = y_perm_y2(site_ind == k);
                y_perm_y2(site_ind == k) = y_tmp_y2(perm_idx);
            end
            
            y_train_resid = y_perm_y0(train_ind);
            y_test_resid = y_perm_y2(test_ind);
            % predict
            beta = beta_pre * y_train_resid;
            alpha = inv_K_r * (y_train_resid - X * beta);
            
            y_predicted = FSM_pred * alpha + ones(num_test_subj,1) .* beta;
            for k = 1:length(metrics)
                stats_perm.(metrics{k})(i,j) = ...
                    CBIG_compute_prediction_acc_and_loss(y_predicted,y_test_resid,metrics{k},y_train_resid);
            end
        end
        save(result_file,'pred_stats_true','loss_true','stats_perm');
    end
end
end
