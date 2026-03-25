function [med,q25,q75] = CBIG_LBC_violin_medianIQR(CogChange_resid_z, outpath)
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% ===== Panel C: Violin + mean ± SD for scaled CogChange =====
% CogChange_resid_z : N x M matrix (scaled longitudinal change)

[N,M] = size(CogChange_resid_z);

% --- Colors (8 tasks) ---
colors = [
    186/255,  74/255,  33/255   % RAVLT
    158/255,  66/255, 103/255   % LMT
    201/255, 122/255, 26/255   % PicVocab
    250/255, 215/255, 140/255      %242/255, 196/255, 110/255   % Flanker
    180/255, 198/255, 230/255   % Pattern
    131/255, 164/255, 215/255   % Picture
    135/255, 125/255, 187/255   % Reading
     81/255,  69/255,  96/255   % PC1
];

%% --- Figure (45 × 27 mm) ---
width_in  = 45/25.4;
height_in = 27/25.4;

fig = figure('Units','inches','Position',[1 1 width_in height_in],'Color','w');
ax  = axes(fig); hold(ax,'on');

maxHalfWidth = 0.35;

%% --- Data-driven ylim (percentile-based), then ensure it covers fixed ticks ---
allVals = CogChange_resid_z(:);
P = prctile(allVals,[0.5 99.5]);
yrange = P(2) - P(1);
ylims_data  = [P(1) - 0.25*yrange,  P(2) + 0.25*yrange];

% Fixed desired ticks
yticks = -4 : 3 : 5;

% Final y-limits must at least include [-4, 5]
ylims = [min(ylims_data(1), min(yticks)), ...
         max(ylims_data(2), max(yticks))];

%% ===== PLOT =====
med = zeros (M,1);
q25 = zeros (M,1);
q75 = zeros (M,1);
for t = 1:M
    y = CogChange_resid_z(:,t);
    y = y(~isnan(y));
    
    % --- KDE for violin (robust to outliers via percentiles) ---
    p = prctile(y, [0.5 99.5]);
    yi = linspace(p(1), p(2), 200);
    [f, ~] = ksdensity(y, yi);
    
    f = f / max(f) * maxHalfWidth;
    x_left  = t - f;
    x_right = t + f;
    
    % 1. Violin with black border
    patch('XData', [x_left fliplr(x_right)], ...
          'YData', [yi     fliplr(yi)], ...
          'FaceColor', colors(t,:), ...
          'FaceAlpha', 0.9, ...
          'EdgeColor', 'k', ...
          'LineWidth', 0.5, ...
          'Parent', ax);
    
    % --- Median + IQR ---
    med(t) = median(y,'omitnan');
    q25(t) = prctile(y,25);
    q75(t)= prctile(y,75);
    
    % IQR bar
    plot(ax, [t t], [q25(t) q75(t)], ...
         'k-', 'LineWidth', 1.2);
    
    % Median point
    scatter(ax, t, med(t), ...
            10, 'k', 'filled');
end

%% ===== Axis formatting =====
xlim(ax, [0.5 M+0.5]);
ylim(ax, ylims);

% ===== Reference line at y = 0 (behind violins) =====
h0 = plot(ax, xlim(ax), [0 0], ':', ...
    'Color', [0.5 0.5 0.5], ...
    'LineWidth', 0.25);

% Force it behind everything (bottom of stack)
ch = ax.Children;
ax.Children = [ch(ch ~= h0); h0];

set(ax, 'XTick', 1:M, ...
        'YTick', yticks, ...              % <-- fixed: -4 : 3 : 5
        'XTickLabel', [], ...
        'YTickLabel', [], ...
        'TickDir', 'out', ...
        'TickLength', [0.02 0.02], ...
        'LineWidth', 0.6, ...
        'FontSize', 7, ...
        'Box', 'off');

disp(yticks);

%% ===== Save PDF =====
set(fig,'PaperUnits','inches');
set(fig,'PaperSize',[width_in height_in]);
set(fig,'PaperPosition',[0 0 width_in height_in]);
print(fig, outpath, '-dpdf','-painters');

end