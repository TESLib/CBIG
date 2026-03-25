function CBIG_LBC_plot_region_map(region_mean, colors, min_thresh, max_thresh, outputfile, dpi, width_cm, height_cm)
% CBIG_LBC_plot_region_map(region_mean, colors, min_thresh, max_thresh, outputfile, dpi, width_cm, height_cm)
%
% Visualize region-wise scalar values (e.g., stability scores) projected
% onto the fsaverage inflated cortical surface using the Yan 400-parcel /
% Kong 17-network parcellation. The figure is saved as a .tif file.
%
% Input:
%     - region_mean: (400 x 1 or 419 x 1 vector)
%           Region-wise scalar values. Only the first 400 cortical parcels
%           are projected onto the surface; subcortical entries are ignored.
%           NaN values are treated as 0.
%
%     - colors: (N x 3 matrix)
%           Colormap in RGB format (values in [0, 1]).
%           Interpolated to 256 levels if fewer than 256 rows.
%
%     - min_thresh: (scalar)
%           Minimum threshold for color scaling (values below are clipped).
%
%     - max_thresh: (scalar)
%           Maximum threshold for color scaling (values above are clipped).
%
%     - outputfile: (string)
%           Full path to save the output image (e.g., 'figs/region_map.tif').
%
%     - dpi: (scalar)
%           Resolution of the output image in dots per inch.
%
%     - width_cm: (scalar)
%           Width of the output figure in centimeters.
%
%     - height_cm: (scalar)
%           Height of the output figure in centimeters.
%
% Output:
%     - A .tif figure is saved to outputfile.
%
% Example:
%     colors = [0,230,255; 0,0,255; 0,0,0; 255,0,0; 255,255,0] / 255;
%     CBIG_LBC_plot_region_map(stability_vec, colors, 0, 0.8, 'region.tif', 300, 16, 4)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
load(fullfile(repo_root,'util','Yan_400label','NetworkIndex_YanKong17.mat'));

%load parcellation
[vertex_label_L, colortable_L] = CBIG_read_annotation(fullfile(getenv('CBIG_CODE_DIR'), ...
    'stable_projects', 'brain_parcellation', 'Yan2023_homotopic', ...
    'parcellations', 'FreeSurfer', 'fsaverage', 'label', 'kong17', ...
    'lh.400Parcels_Kong2022_17Networks.annot'));
[vertex_label_R, colortable_R] = CBIG_read_annotation(fullfile(getenv('CBIG_CODE_DIR'), ...
    'stable_projects', 'brain_parcellation', 'Yan2023_homotopic', ...
    'parcellations', 'FreeSurfer', 'fsaverage', 'label', 'kong17', ...
    'rh.400Parcels_Kong2022_17Networks.annot'));
lh_label = vertex_label_L-1;
rh_label = vertex_label_R-1;

lh_data = zeros(163842,1);
rh_data = zeros(163842,1);

region_mean(isnan(region_mean)) = 0;
% for i=1:200
%     lh_data(lh_label==i)=region_mean(i);
%     rh_data(rh_label==i)=region_mean(200+i);
% end

for i=1:200
    lh_data(lh_label==i)=region_mean(i);
    rh_data(rh_label==i)=region_mean(200+i);
end
region_mean_cortex = region_mean(1:400);
min(region_mean_cortex)
max(region_mean_cortex)

%% with boundary

 lh_labels = lh_label;
 rh_labels = rh_label;
 mesh_name = 'fsaverage';
 surf_type = 'inflated';
% The remaining rows correspond to the red shades


% Interpolate to get a smoother (e.g., 256-level) colormap

n_old = size(colors, 1);
if n_old < 256
    n_new = 256;
    old_idx = linspace(1, n_old, n_old);
    new_idx = linspace(1, n_old, n_new);
    custom_colormap = interp1(old_idx, colors, new_idx, 'linear');
else
    % Already have 256 or more rows
    custom_colormap = colors;
end

% CBIG_DrawSurfaceMaps(lh_data, rh_data, ...
%     mesh_name, surf_type, min_thresh, max_thresh, colors)
CBIG_DrawSurfaceMapsWithBoundary(lh_data, rh_data, ...
    lh_labels, rh_labels, mesh_name, surf_type, min_thresh, max_thresh,custom_colormap)
% Convert to inches
width_in = width_cm / 2.54;
height_in = height_cm / 2.54;

% Apply figure size settings
fig = gcf;  % get current figure handle
set(fig, 'Units', 'inches', 'Position', [0 0 width_in height_in]);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [width_in height_in]);
set(fig, 'PaperPosition', [0 0 width_in height_in]);
set(fig, 'PaperPositionMode', 'manual');
set(fig, 'InvertHardcopy', 'off');  % keep background color

% Save as .tif
print(fig, outputfile, '-dtiff', ['-r', num2str(dpi)]);
end
