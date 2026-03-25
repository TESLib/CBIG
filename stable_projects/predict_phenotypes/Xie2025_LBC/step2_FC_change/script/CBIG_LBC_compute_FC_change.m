function CBIG_LBC_compute_FC_change(subname, REPO_ROOT, LBC_rep_dir, ABCD_preprocessed)
% CBIG_LBC_compute_FC_change(subname, REPO_ROOT, LBC_rep_dir, ABCD_preprocessed)
%
% Compute individual-level FC change (Year 2 - Year 0) using xDF
% autocorrelation-corrected z-statistics.
%
% Input:
%     - subname: (string)
%           Subject ID (e.g., 'NDAR_XXXXXXXX').
%
%     - REPO_ROOT: (string)
%           Path to repo root (Xie2025_LBC directory).
%
%     - LBC_rep_dir: (string)
%           Path to replication directory.
%
%     - ABCD_preprocessed: (string)
%           Path to preprocessed ABCD data directory containing 'y0' and 'y2'
%           subdirectories.
%
% Output:
%     - FC_diff.mat saved to [LBC_rep_dir]/FC_change/[subname]/ containing
%       struct FC with fields: z, z_fdr, p.
%
% Example:
%     CBIG_LBC_compute_FC_change('NDAR_XXXXXXXX', '/path/to/Xie2025_LBC', ...
%         '/path/to/rep', '/path/to/ABCD_preprocessed')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

addpath(genpath(fullfile(REPO_ROOT, 'util', 'xDF')));

FC_analysis_dir    = fullfile(LBC_rep_dir, 'FC_change', subname);
Y0_Y0PROC_REST_DIR = fullfile(ABCD_preprocessed, 'y0', 'rs_GSR_mf_FD0.3_DVARS50', 'mproc_R4', subname);
Y2_Y0PROC_REST_DIR = fullfile(ABCD_preprocessed, 'y2', 'rs_GSR_mf_FD0.3_DVARS50', 'mproc_R4', subname);

if ~exist(FC_analysis_dir, 'dir')
    mkdir(FC_analysis_dir);
end

vertex_label_left_file  = fullfile(REPO_ROOT, 'util', 'Yan_400label', 'fsaverage6', ...
    'lh.400Parcels_Kong2022_17Networks.annot');
vertex_label_right_file = fullfile(REPO_ROOT, 'util', 'Yan_400label', 'fsaverage6', ...
    'rh.400Parcels_Kong2022_17Networks.annot');
subcort_labels_Y0 = fullfile(Y0_Y0PROC_REST_DIR,'FC_metrics', 'ROIs',[subname '.subcortex.19aseg.func.nii.gz']);
subcort_labels_Y2 = fullfile(Y2_Y0PROC_REST_DIR,'FC_metrics', 'ROIs',[subname '.subcortex.19aseg.func.nii.gz']);

Y0_params = prepare_data_lists(Y0_Y0PROC_REST_DIR, subname);
Y2_params = prepare_data_lists(Y2_Y0PROC_REST_DIR, subname);

FC_diff = compare_Y0_Y2(vertex_label_left_file, vertex_label_right_file, ...
    subcort_labels_Y0, subcort_labels_Y2, Y0_params, Y2_params);

save(fullfile(FC_analysis_dir, 'FC_diff.mat'), 'FC_diff');

rmpath(genpath(fullfile(REPO_ROOT, 'util', 'xDF')));

end

% -- Helper: compare Y0 and Y2 FC ------------------------------------------
function FC = compare_Y0_Y2(vertex_label_left_file, vertex_label_right_file, ...
    subcort_labels_Y0, subcort_labels_Y2, Y0_params, Y2_params)

Y0_params.lh_labels_file   = vertex_label_left_file;
Y0_params.rh_labels_file   = vertex_label_right_file;
Y0_params.subcort_labels   = subcort_labels_Y0;

Y2_params.lh_labels_file   = vertex_label_left_file;
Y2_params.rh_labels_file   = vertex_label_right_file;
Y2_params.subcort_labels   = subcort_labels_Y2;

[~, Stat_Y0] = compute_FC(Y0_params);
[~, Stat_Y2] = compute_FC(Y2_params);

FC = FC_stat(Stat_Y0, Stat_Y2);

end

% -- Helper: prepare data file lists ---------------------------------------
function params = prepare_data_lists(PREPROC_REST_DIR, subname)

BOLD_remain = fullfile(PREPROC_REST_DIR, 'logs', [subname '_pass_qc.bold']);
if ~exist(BOLD_remain, 'file')
    error('QC file not found: %s\nCheck that ABCD_preprocessed path and subject ID are correct.', BOLD_remain);
end
fid         = fopen(BOLD_remain);
BOLD_remain = textscan(fid, '%s');
fclose(fid);

if isempty(BOLD_remain{1})
    error('No BOLD runs survived after censoring for subject: %s', subname);
end

for bld = 1:length(BOLD_remain{1})
    run_id = BOLD_remain{1}{bld};
    params.censor_list{bld}      = fullfile(PREPROC_REST_DIR, 'qc', ...
        [subname '_bld' run_id '_FDRMS0.3_DVARS50_motion_outliers.txt']);
    params.lh_fMRI_list{bld}     = fullfile(PREPROC_REST_DIR, 'surf', ...
        ['lh.' subname '_bld' run_id '_rest_mc_skip_residc_interp_FDRMS0.3_DVARS50_bp_0.009_0.08_fs6_sm6.nii.gz']);
    params.rh_fMRI_list{bld}     = fullfile(PREPROC_REST_DIR, 'surf', ...
        ['rh.' subname '_bld' run_id '_rest_mc_skip_residc_interp_FDRMS0.3_DVARS50_bp_0.009_0.08_fs6_sm6.nii.gz']);
    params.subcort_fMRI_list{bld} = fullfile(PREPROC_REST_DIR, 'bold', run_id, ...
        [subname '_bld' run_id '_rest_mc_skip_residc_interp_FDRMS0.3_DVARS50_bp_0.009_0.08.nii.gz']);
end

end

% -- Helper: compute FC statistics -----------------------------------------
function FC = FC_stat(Stat_Y0, Stat_Y2)

rzf = (Stat_Y2.rf - Stat_Y0.rf) ./ sqrt(Stat_Y2.sf + Stat_Y0.sf);
rzf(1:size(rzf,1)+1:end) = 0;
f_pval = 2 .* normcdf(-abs(rzf));
f_pval(1:size(rzf,1)+1:end) = 0;
FC.z_fdr = fdr_bh(f_pval) .* rzf;
FC.p     = f_pval;
FC.z     = rzf;

end

% -- Helper: compute FC using xDF ------------------------------------------
function [VarHatRho, Stat] = compute_FC(params)

vertex_label_left = CBIG_read_annotation(params.lh_labels_file);
regions           = unique(vertex_label_left(vertex_label_left ~= 1));
ROI_cell_left     = cell(1, 200);
for i = 1:length(regions)
    ROI_cell_left{i} = find(vertex_label_left == regions(i));
end

vertex_label_right = CBIG_read_annotation(params.rh_labels_file);
regions            = unique(vertex_label_right(vertex_label_right ~= 1));
ROI_cell_right     = cell(1, 200);
for i = 1:length(regions)
    ROI_cell_right{i} = find(vertex_label_right == regions(i));
end

subcort_labels    = MRIread(params.subcort_labels);
regions           = unique(subcort_labels.vol(subcort_labels.vol ~= 0));
ROI_cell_subcort  = cell(1, 19);
for i = 1:length(regions)
    ROI_cell_subcort{i} = find(subcort_labels.vol == regions(i));
end

lh_data_all = []; rh_data_all = []; subcort_data_all = [];
for n = 1:length(params.censor_list)
    censor_frames     = load(params.censor_list{n});
    lh_fMRI_data      = MRIread(params.lh_fMRI_list{n});
    rh_fMRI_data      = MRIread(params.rh_fMRI_list{n});
    subcort_fMRI_data = MRIread(params.subcort_fMRI_list{n});

    lh_data      = reshape(lh_fMRI_data.vol,      [], size(lh_fMRI_data.vol,      4));
    rh_data      = reshape(rh_fMRI_data.vol,      [], size(rh_fMRI_data.vol,      4));
    subcort_data = reshape(subcort_fMRI_data.vol, [], size(subcort_fMRI_data.vol, 4));

    lh_data      = lh_data(:,      censor_frames == 1);
    rh_data      = rh_data(:,      censor_frames == 1);
    subcort_data = subcort_data(:, censor_frames == 1);

    lh_data      = bsxfun(@minus,  lh_data,      CBIG_nanmean(lh_data,      2));
    lh_data      = bsxfun(@rdivide,lh_data,      CBIG_nanstd(lh_data',      1)');
    rh_data      = bsxfun(@minus,  rh_data,      CBIG_nanmean(rh_data,      2));
    rh_data      = bsxfun(@rdivide,rh_data,      CBIG_nanstd(rh_data',      1)');
    subcort_data = bsxfun(@minus,  subcort_data, CBIG_nanmean(subcort_data, 2));
    subcort_data = bsxfun(@rdivide,subcort_data, CBIG_nanstd(subcort_data', 1)');

    lh_data_all      = [lh_data_all,      lh_data];
    rh_data_all      = [rh_data_all,      rh_data];
    subcort_data_all = [subcort_data_all, subcort_data];
end

curr_mean_data_left    = aggregate_ROI(lh_data_all,      ROI_cell_left);
curr_mean_data_right   = aggregate_ROI(rh_data_all,      ROI_cell_right);
curr_mean_data_subcort = aggregate_ROI(subcort_data_all, ROI_cell_subcort);

curr_mean_data = [curr_mean_data_left; curr_mean_data_right; curr_mean_data_subcort];
[VarHatRho, Stat] = xDF(curr_mean_data, size(curr_mean_data, 2), ...
    'truncate', 'adaptive', 'TVOff');
% NOTE: rmpath for xDF is handled in the main function, not here

end

% -- Helper: average fMRI signal within each ROI ---------------------------
function mean_data = aggregate_ROI(fMRI_data, ROI_cell)

mean_data = zeros(length(ROI_cell), size(fMRI_data, 2));
for i = 1:length(ROI_cell)
    if isempty(ROI_cell{i})
        mean_data(i, :) = nan;
    else
        mean_data(i, :) = CBIG_nanmean(fMRI_data(ROI_cell{i}, :), 1);
    end
end

end
