function CBIG_LBC_preproc_FCmetrics_Nmin(lh_cortical_ROIs_file, rh_cortical_ROIs_file, ...
    subcortical_ROIs_file, lh_cortical_data_list, ...
    rh_cortical_data_list, subcortical_data_list, discard_frames_list, metric_type, output_dir, output_prefix)
% CBIG_LBC_preproc_FCmetrics_Nmin(lh_cortical_ROIs_file, rh_cortical_ROIs_file,
%     subcortical_ROIs_file, lh_cortical_data_list, rh_cortical_data_list,
%     subcortical_data_list, discard_frames_list, metric_type, output_dir, output_prefix)
%
% Compute FC metrics for truncated scan durations (Nmin). Computes 6 sub-matrices
% (lh2lh, lh2rh, rh2rh, lh2subcort, rh2subcort, subcort2subcort) per time window
% using CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin.
%
% Input:
%     - lh_cortical_ROIs_file: (string)
%           Full path to cortical ROI parcellation file for the left hemisphere
%           (e.g., lh.Schaefer2018_400Parcels_17Networks_order.annot).
%
%     - rh_cortical_ROIs_file: (string)
%           Full path to cortical ROI parcellation file for the right hemisphere.
%
%     - subcortical_ROIs_file: (string)
%           Full path to subcortical ROI file in volumetric space
%           (e.g., subject.subcortex.parcels.func.nii.gz).
%
%     - lh_cortical_data_list: (string)
%           One-line text file listing left hemisphere fMRI files for all runs
%           of one subject, separated by spaces.
%
%     - rh_cortical_data_list: (string)
%           One-line text file listing right hemisphere fMRI files for all runs.
%
%     - subcortical_data_list: (string)
%           One-line text file listing volumetric fMRI files for all runs.
%
%     - discard_frames_list: (string)
%           One-line text file listing discarded frames files for all runs, or
%           'NONE' if motion scrubbing is not needed.
%
%     - metric_type: (string)
%           FC metric type. Currently supports 'Pearson_r' only.
%
%     - output_dir: (string)
%           Full path of output directory.
%
%     - output_prefix: (string)
%           Prefix for output files. Per-run and per-time-window sub-matrix
%           .mat files are saved under [output_dir]/<time_window>/.
%
% Output:
%     - Per-run .mat files saved under [output_dir]/<time_window>/ for each
%       sub-matrix type (_lh2lh, _lh2rh, _rh2rh, _lh2subcort, _rh2subcort,
%       _subcort2subcort), plus a completion flag file.
%
% Example:
%     CBIG_LBC_preproc_FCmetrics_Nmin('lh.annot', 'rh.annot', 'subcort.nii.gz', ...
%         'lh_data.txt', 'rh_data.txt', 'subcort_data.txt', 'NONE', 'Pearson_r', ...
%         '/path/out', 'sub001')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

if(strcmp(metric_type, 'Pearson_r'))
    if(~exist(output_dir))
        mkdir(output_dir);
    end

    %%% compute lh to lh correlation
    lh2lh_out_file = [output_dir '/' output_prefix '_lh2lh.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(lh2lh_out_file, ...
        lh_cortical_data_list, lh_cortical_data_list, discard_frames_list, ...
        lh_cortical_ROIs_file, lh_cortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% compute lh to rh correlation
    lh2rh_out_file = [output_dir '/' output_prefix '_lh2rh.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(lh2rh_out_file, ...
        lh_cortical_data_list, rh_cortical_data_list, discard_frames_list, ...
        lh_cortical_ROIs_file, rh_cortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% compute rh to rh correlation
    rh2rh_out_file = [output_dir '/' output_prefix '_rh2rh.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(rh2rh_out_file, ...
        rh_cortical_data_list, rh_cortical_data_list, discard_frames_list, ...
        rh_cortical_ROIs_file, rh_cortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% compute lh to subcortical correlation
    lh2subcort_out_file = [output_dir '/' output_prefix '_lh2subcort.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(lh2subcort_out_file, ...
        lh_cortical_data_list, subcortical_data_list, discard_frames_list, ...
        lh_cortical_ROIs_file, subcortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% compute rh to subcortical correlation
    rh2subcort_out_file = [output_dir '/' output_prefix '_rh2subcort.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(rh2subcort_out_file, ...
        rh_cortical_data_list, subcortical_data_list, discard_frames_list, ...
        rh_cortical_ROIs_file, subcortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% compute subcortical to subcortical correlation
    subcort2subcort_out_file = [output_dir '/' output_prefix '_subcort2subcort.mat'];
    CBIG_LBC_ComputeROIs2ROIsCorrelationMatrix_Nmin(subcort2subcort_out_file, ...
        subcortical_data_list, subcortical_data_list, discard_frames_list, ...
        subcortical_ROIs_file, subcortical_ROIs_file, 'NONE', 'NONE', 1);
    
    %%% combine
    %lh2lh = load(lh2lh_out_file);
    %lh2rh = load(lh2rh_out_file);
    %rh2rh = load(rh2rh_out_file);
    %lh2subcort = load(lh2subcort_out_file);
    %rh2subcort = load(rh2subcort_out_file);
    %subcort2subcort = load(subcort2subcort_out_file);
    %if (~isequal(size(subcort2subcort.corr_mat),[19,19]))
    %    error('The number of subcortical ROIs is not 19. FC matrix will not be saved.')
    %end
   % lh2all = [lh2lh.corr_mat lh2rh.corr_mat lh2subcort.corr_mat];
    %rh2all = [lh2rh.corr_mat' rh2rh.corr_mat rh2subcort.corr_mat];
    %subcort2all = [lh2subcort.corr_mat' rh2subcort.corr_mat' subcort2subcort.corr_mat];
    
    %corr_mat = [lh2all; rh2all; subcort2all];
    %save([output_dir '/' output_prefix '_all2all.mat'], 'corr_mat');
    flag_file = fullfile(output_dir, [output_prefix, '.flag']);
    fid = fopen(flag_file, 'w');
    if fid == -1
        warning('Could not create flag file: %s', flag_file);
    else
        fprintf(fid, 'Finished computing all correlations, including subcortical-to-subcortical.\n');
        fclose(fid);
    end
    fprintf('Finished computing all correlations, including subcortical-to-subcortical.\n');
    exit;
else
    error('Unknown metric_type.');
end


end

