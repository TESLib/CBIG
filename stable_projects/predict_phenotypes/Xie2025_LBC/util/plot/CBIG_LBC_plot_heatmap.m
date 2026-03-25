function CBIG_LBC_plot_heatmap(repre_sub, vmin, vmax, colormap_mat_path, ...
    heatmap_path, colorbar_path, width_cm, height_cm)
% CBIG_LBC_plot_heatmap(repre_sub, vmin, vmax, colormap_mat_path, heatmap_path, colorbar_path, width_cm, height_cm)
%
% Plot a matrix as a heatmap with a diverging colormap and export both the
% heatmap and a standalone colorbar as PDF files.
%
% Input:
%     - repre_sub: (N x M matrix)
%           Matrix of values to visualize (e.g., cognitive change residuals
%           for representative subjects). N = rows, M = columns.
%
%     - vmin: (scalar)
%           Minimum value of the colorbar range.
%
%     - vmax: (scalar)
%           Maximum value of the colorbar range.
%
%     - colormap_mat_path: (string)
%           Path to a .mat file containing variable 'colors' (N x 3
%           BlueWhiteRed colormap, values in [0, 1]).
%
%     - heatmap_path: (string)
%           Output path for the heatmap PDF.
%
%     - colorbar_path: (string)
%           Output path for the standalone vertical colorbar PDF.
%
%     - width_cm: (scalar)
%           Width of the output figure in centimeters.
%
%     - height_cm: (scalar)
%           Height of the output figure in centimeters.
%
% Output:
%     - A heatmap PDF saved to heatmap_path.
%     - A colorbar PDF saved to colorbar_path.
%
% Example:
%     CBIG_LBC_plot_heatmap(data, -0.5, 0.5, 'colors.mat', 'heatmap.pdf', 'colorbar.pdf', 6, 4)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Build custom diverging colormap
load(colormap_mat_path, 'colors');
mid_idx = 26;

n_total = 256;
neg_ratio = abs(vmin) / (abs(vmin) + vmax);
n_neg = round(n_total * neg_ratio);
n_pos = n_total - n_neg;

neg_part = colors(1:mid_idx, :);
pos_part = colors(mid_idx:end, :);

interp_neg = interp1(linspace(0, 1, size(neg_part, 1)), neg_part, linspace(0, 1, n_neg), 'pchip');
interp_pos = interp1(linspace(0, 1, size(pos_part, 1)), pos_part, linspace(0, 1, n_pos), 'pchip');

cmap = [interp_neg; interp_pos];

%% Plot heatmap
figure;
imagesc(repre_sub);
colormap(cmap);
caxis([vmin, vmax]);
set(gca, 'XTick', [], 'YTick', []);
set(gca, 'YDir', 'reverse');
axis off;
set(gca, 'Units', 'normalized', 'Position', [0 0 1 1]);

% Draw grid lines
[n_rows, n_cols] = size(repre_sub);
hold on;
for r = 1:n_rows+1
    y = n_rows + 0.5 - (r - 1);
    plot([0.5, n_cols + 0.5], [y, y], 'k', 'LineWidth', 0.25);
end
for c = 1:n_cols+1
    if c == n_cols + 1
        x = c - 0.5 - 0.01;
    else
        x = c - 0.5;
    end
    plot([x, x], [0.5, n_rows + 0.5], 'k', 'LineWidth', 0.25);
end
xlim([0.5, n_cols + 0.5 + 0.01]);
ylim([0.5, n_rows + 0.5]);

% Set figure size (in cm)

width_in = width_cm / 2.54;
height_in = height_cm / 2.54;

set(gcf, 'Units', 'inches', 'Position', [0 0 width_in height_in]);
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [width_in height_in]);
set(gcf, 'PaperPosition', [0 0 width_in height_in]);
set(gcf, 'PaperPositionMode', 'manual');

% Export heatmap to PDF
print(heatmap_path, '-dpdf', '-painters');

%% Draw colorbar only
clim = [vmin, vmax];
size_cm = [0.6, 4];  % Width x height
cb_position = [0.3, 0.1, 0.4, 0.8];  % [x, y, w, h]
CBIG_LBC_draw_colorbar(cmap, clim, size_cm, colorbar_path, 'vertical', cb_position);

end
