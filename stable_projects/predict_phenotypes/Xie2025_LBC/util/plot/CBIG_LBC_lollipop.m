function CBIG_LBC_lollipop(cohen_d, outpath)
% CBIG_LBC_lollipop(cohen_d, outpath)
%
% Plot a lollipop chart of Cohen's d effect sizes for M cognitive measures,
% with measure-specific colored dots and thin vertical stems from zero.
%
% Input:
%     - cohen_d: (1 x M or M x 1 vector)
%           Cohen's d effect sizes for M cognitive measures. Expected M = 8
%           (RAVLT, LMT, PicVocab, Flanker, Pattern, Picture, Reading, PC1).
%
%     - outpath: (string)
%           Full path to save the output figure (PDF).
%
% Output:
%     - A PDF figure saved to outpath.
%
% Example:
%     CBIG_LBC_lollipop([0.3 0.5 0.2 0.4 0.6 0.35 0.25 0.45], 'cohen_d.pdf')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

M = numel(cohen_d);

%% Colors
colors = [
    186/255,  74/255,  33/255
    158/255,  66/255, 103/255
    201/255, 122/255, 26/255
    250/255, 215/255, 140/255 
    180/255, 198/255, 230/255
    131/255, 164/255, 215/255
    135/255, 125/255, 187/255
     81/255,  69/255,  96/255
];

%% Figure size (45 × 27 mm)
width_in  = 45/25.4;
height_in = 27/25.4;

fig = figure('Color','w','Units','inches',...
             'Position',[1 1 width_in height_in]);
ax = axes(fig); hold(ax,'on');

%% Fixed y-ticks and limits
% yticks = -0.2 : 0.4 : 1.4;
yticks = 0 : 0.2 : 0.8;
ylim(ax, [min(yticks) max(yticks)]);

%% --- Draw y = 0 horizontal reference line ---
% plot(ax, [0.5 M+0.5], [0 0], 'k-', 'LineWidth', 0.2);

%% Lollipop plot
for t = 1:M
    
    % Vertical stem from 0 to Cohen?s d
    plot(ax, [t t], [0 cohen_d(t)], ...
         'Color',[0.3 0.3 0.3], 'LineWidth', 1);

    % Dot at the effect size
    scatter(ax, t, cohen_d(t), ...
            20, colors(t,:), 'filled', ...
            'MarkerEdgeColor','k', 'LineWidth', 0.2);
end

%% Axis settings
xlim(ax, [0.5 M+0.5]);

set(ax, 'XTick', 1:M, ...
        'YTick', yticks, ...
        'XTickLabel', [], ...
        'YTickLabel', [], ...
        'TickDir','out', ...
        'TickLength',[0.02 0.02], ...
        'LineWidth',0.5, ...
        'FontSize',7);

box(ax,'off');

%% Save PDF
set(fig,'PaperUnits','inches');
set(fig,'PaperSize',[width_in height_in]);
set(fig,'PaperPosition',[0 0 width_in height_in]);
print(fig,outpath,'-dpdf','-painters');

end