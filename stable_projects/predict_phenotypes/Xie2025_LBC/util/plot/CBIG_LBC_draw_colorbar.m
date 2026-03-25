function CBIG_LBC_draw_colorbar(colors, clim, size_cm, filename, orientation, cb_position)
% CBIG_LBC_draw_colorbar(colors, clim, size_cm, filename, orientation, cb_position)
%
% Export a clean standalone colorbar with border to a PDF file.
%
% Input:
%     - colors: (N x 3 matrix)
%           Colormap array. Each row is an [R G B] value in [0, 1].
%           Interpolated to 256 levels if fewer than 256 rows.
%
%     - clim: (1 x 2 vector)
%           Color axis limits [min max].
%
%     - size_cm: (1 x 2 vector)
%           Figure size in centimeters [width height].
%
%     - filename: (string)
%           Output file path (e.g., 'colorbar.pdf').
%
% Optional input:
%     - orientation: (string)
%           'vertical' (default) or 'horizontal'.
%
%     - cb_position: (1 x 4 vector)
%           Colorbar position [left bottom width height] in normalized units.
%
% Output:
%     - A standalone colorbar PDF is saved to filename.
%
% Example:
%     colors = [0,0,1; 1,1,1; 1,0,0];
%     CBIG_LBC_draw_colorbar(colors, [-1 1], [0.6 4], 'colorbar.pdf', 'vertical', [0.3 0.1 0.4 0.8])
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

if nargin < 6
    orientation = 'vertical';
end

% Interpolate colormap to 256 for smoothness
n_old = size(colors, 1);
if n_old < 256
    custom_colormap = interp1(1:n_old, colors, linspace(1, n_old, 256), 'linear');
else
    custom_colormap = colors;
end

figure('Visible', 'off');

% Create dummy image for colorbar to link to
h = imagesc([0 1]);
colormap(custom_colormap);
caxis(clim);

% Hide dummy axes
set(h, 'Visible', 'off');
set(gca, 'Visible', 'off');

% Add colorbar
if strcmpi(orientation, 'horizontal')
    cb = colorbar('SouthOutside');
else
    cb = colorbar;
    set(cb, 'Location', 'east');
    set(cb, 'YAxisLocation', 'right');  % Only meaningful for vertical
end

% --- Colorbar formatting ---
set(cb, 'TickDirection', 'in');      % Ticks inside
set(cb, 'Box', 'on');                % Border around colorbar
set(cb, 'LineWidth', 0.5);
set(cb, 'FontSize', 5);
set(cb, 'TickLabels', []);           % No tick text

% Custom position if provided
if nargin == 6 && numel(cb_position) == 4
    set(cb, 'Position', cb_position);
end

axis off;

% Paper size setup
width_cm = size_cm(1);
height_cm = size_cm(2);
width_in = width_cm / 2.54;
height_in = height_cm / 2.54;

set(gcf, 'Units', 'inches', 'Position', [0 0 width_in height_in]);
set(gcf, 'PaperUnits', 'inches', ...
         'PaperSize', [width_in height_in], ...
         'PaperPosition', [0 0 width_in height_in], ...
         'PaperPositionMode', 'manual');

% Export
print(filename, '-dpdf', '-painters');
close;
end
