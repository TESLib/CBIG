function CBIG_LBC_plot_network_matrix(edgeVector, colors, colorbar_min, colorbar_max, ...
    outputfile, dpi, width_cm, height_cm)
% CBIG_LBC_plot_network_matrix(edgeVector, colors, colorbar_min, colorbar_max, outputfile, dpi, width_cm, height_cm)
%
% Plot a 419 x 419 network connectivity matrix from a vectorized edge
% vector, reordered by the Yan 400-parcel / Kong 17-network parcellation,
% with minor and major network boundary lines, and a left-side network
% color bar. The figure is saved as a .tif file.
%
% Input:
%     - edgeVector: (1 x 87571 vector)
%           Upper triangular entries (excluding diagonal) of a symmetric
%           419 x 419 connectivity matrix, as returned by squareform.
%           E = 419*(419-1)/2 = 87571.
%
%     - colors: (C x 3 matrix)
%           RGB colormap for the heatmap (values in [0, 1]).
%           Interpolated to 256 levels if fewer than 256 rows.
%
%     - colorbar_min: (scalar)
%           Minimum value for the color scale.
%
%     - colorbar_max: (scalar)
%           Maximum value for the color scale.
%
%     - outputfile: (string)
%           Full path to save the output image (e.g., 'figs/matrix.tif').
%
%     - dpi: (scalar)
%           Resolution of the output image in dots per inch.
%
%     - width_cm: (scalar)
%           Width of the figure in centimeters.
%
%     - height_cm: (scalar)
%           Height of the figure in centimeters.
%
% Output:
%     - A .tif figure is saved to outputfile.
%
% Example:
%     colors = [0,230,255; 0,0,255; 0,0,0; 255,0,0; 255,255,0] / 255;
%     CBIG_LBC_plot_network_matrix(fc_vector, colors, -1.2, 1.2, 'matrix.tif', 300, 5, 4.8)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
% Load network labels
res = 400;
group_labels = ft_read_cifti(fullfile(repo_root,'util','Yan_400label',...
    [num2str(res) 'Parcels_Kong2022_17Networks.dlabel.nii']), 'mapname', 'array');
parcelname = group_labels.dlabellabel';

network_order_struct = {{'DefaultC', 'DefaultB', 'DefaultA'},
                        {'ContC', 'ContB', 'ContA'},
                        {'Language'},
                        {'SalVenAttnB', 'SalVenAttnA'},
                        {'DorsAttnB', 'DorsAttnA'},
                        {'Aud'},
                        {'SomMotB', 'SomMotA'},
                        {'VisualC', 'VisualB', 'VisualA'}};

[Index, major_grid, minor_grid, network_order_name] = CBIG_PlotCorrMat_reorder_labels(res, ...
    parcelname, network_order_struct);
Index = [Index; ((res+1):419)'];

edgeVector_mat = squareform(edgeVector);
edgeVector_reOrder = edgeVector_mat(Index, Index);

n_old = size(colors, 1);
if n_old < 256
    n_new = 256;
    old_idx = linspace(1, n_old, n_old);
    new_idx = linspace(1, n_old, n_new);
    custom_colormap = interp1(old_idx, colors, new_idx, 'linear');
else
    custom_colormap = colors;
end

network_colors = [...
    0,0,130; 205,62,78; 255,255,0; 119,140,176;
    135,50,74; 230,148,34; 12,48,255; 255,152,213;
    196,58,250; 0,118,14; 74,155,60; 220,248,164;
    42,204,164; 70,130,180; 122,135,50; 255,0,0;
    120,18,134; 170,150,90] / 255;

% Create figure
fig = figure('Units','centimeters', 'Position',[2, 2, width_cm, height_cm], ...
             'PaperUnits','centimeters', 'PaperPositionMode','manual', ...
             'PaperPosition',[0 0 width_cm height_cm], ...
             'PaperSize',[width_cm height_cm], 'Color','w');

% === 1) Main Heatmap ===
heatmap_width = 0.80;
bar_width = heatmap_width / 25;
bar_gap = 0.015;
left_offset = 0.153;  
bottom_offset = 0.09;

h_main = axes('Position', [left_offset, bottom_offset, heatmap_width, heatmap_width]);
imagesc(edgeVector_reOrder);
colormap(h_main, custom_colormap);
caxis(h_main, [colorbar_min, colorbar_max]);
axis(h_main, 'off', 'tight', 'manual');

% === 2) Draw Grid Lines ===
[xline, yline, ymaj] = generateline(size(edgeVector_reOrder, 1));
network_boundaries = [0, minor_grid, 400, 419];
major_grid = [major_grid, 400];
all_boundaries = network_boundaries(2:end-1);
minor_grid = setdiff(all_boundaries, major_grid);

patch(xline(:, minor_grid), yline(:, minor_grid), 'w', 'EdgeColor', 'w', 'LineWidth', 0.2, 'EdgeAlpha', 0.6);
patch(yline(:, minor_grid), xline(:, minor_grid), 'w', 'EdgeColor', 'w', 'LineWidth', 0.2, 'EdgeAlpha', 0.6);
patch(xline(:, major_grid), ymaj(:, major_grid), 'w', 'EdgeColor', 'w', 'LineWidth', 1, 'EdgeAlpha', 0.9);
patch(ymaj(:, major_grid), xline(:, major_grid), 'w', 'EdgeColor', 'w', 'LineWidth', 1, 'EdgeAlpha', 0.9);

% === 3) Left-Side Colorbar ===

h_side = axes('Position', [left_offset - bar_width - bar_gap, bottom_offset, bar_width, heatmap_width]);

num_networks = length(network_boundaries) - 1;
color_bar_data = zeros(network_boundaries(end), 1);
for i = 1:num_networks
    idx_start = network_boundaries(i) + 1;
    idx_end   = network_boundaries(i + 1);
    color_bar_data(idx_start:idx_end) = i;
end

axes(h_side);
h_img = imagesc(color_bar_data);
colormap(h_side, network_colors(1:num_networks, :));
axis(h_side, 'off', 'tight', 'manual');
h_img.CDataMapping = 'scaled';
set(h_side, 'YLim', get(h_main, 'YLim'));
linkaxes([h_main, h_side], 'y');

% === 4) Export ===
set(fig, 'InvertHardcopy', 'off');
print(fig, outputfile, '-dtiff', ['-r', num2str(dpi)]);

end

function [x, y, ymaj] = generateline(n)
    x = 1.5:1:n;
    x = [ x; x; repmat(nan,1,(n-1)) ];
    y = [ 0.5 n+0.5 nan ].';
    y = repmat(y,1,(n-1));

    ymaj = [ -5 n+5.5 nan]';
    % For short grid (same as the figure boundary) ymaj = [ 0.5 n+0.5 nan]';
    ymaj = repmat(ymaj,1,(n-1));
end
