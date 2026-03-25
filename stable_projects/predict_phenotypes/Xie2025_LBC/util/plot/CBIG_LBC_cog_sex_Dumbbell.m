function CBIG_LBC_cog_sex_Dumbbell(r_female, r_male, outpath,step)
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
% Draw a dumbbell plot for sex-specific cognitive stability (r)
% Female = red, Male = blue, line = grey
% Outputs a vector PDF figure (small size for manuscript)
% step of the y ticks

    behav_names = {'RAVLT','LMT','PicVocab','Flanker', ...
                   'Pattern','Picture','Reading','PC1'};

    if numel(r_female) ~= 8 || numel(r_male) ~= 8
        error('Input vectors must be 8×1.');
    end

    r_female = r_female(:);
    r_male   = r_male(:);
    M = numel(behav_names);
    ypos = 1:M;

    % =====================
    %  Figure parameters
    % =====================
    width_in  = 45/25.4;   % 45 mm
    height_in = 27/25.4;   % 27 mm

    fig = figure('Color','w','Units','inches',...
                 'Position',[1 1 width_in height_in]);
    ax = axes(fig); 
    hold(ax,'on');

    % Colors  
    color_female = [186/255,  74/255,  33/255];%[200 80 80] / 255;      % red
    color_male   = [72 114 196] / 255;     % blue
    color_line   = [0.4 0.4 0.4];          % grey

    % =====================
    %  Plot dumbbells
    % =====================
    for i = 1:M
        plot(ax,[r_female(i) r_male(i)], [ypos(i) ypos(i)], '-', ...
            'Color', color_line, 'LineWidth', 0.8);

        plot(ax, r_female(i), ypos(i), 'o', ...
            'MarkerFaceColor', color_female, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.2, ...
            'MarkerSize', 3);

        plot(ax, r_male(i), ypos(i), 'o', ...
            'MarkerFaceColor', color_male, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.2, ...
            'MarkerSize', 3);
    end

    % =====================
    %  Axis formatting
    % =====================
    all_r = [r_female; r_male];
    xmin = floor((min(all_r) - 0.05)*10)/10;
    xmax = ceil((max(all_r) + 0.05)*10)/10;

    xticks_vals = xmin : step : xmax;

    set(ax, 'YTick', ypos, ...
            'YTickLabel', [], ... % remove labels
            'XTick', xticks_vals, ...
            'XTickLabel', [], ... % remove labels
            'TickDir', 'out', ...
            'FontSize', 8, ...
            'Box', 'off', ...
            'YDir', 'reverse');    % RAVLT on top

    xlim(ax,[xmin xmax]);
    ylim(ax,[0.5 M+0.5]);
disp(xticks_vals)
    % =====================
    %  Save as PDF (vector)
    % =====================
    set(fig,'PaperUnits','inches');
    set(fig,'PaperSize',[width_in height_in]);
    set(fig,'PaperPosition',[0 0 width_in height_in]);

    if nargin >= 3 && ~isempty(outpath)
        print(fig, outpath, '-dpdf', '-painters');
        fprintf('Saved PDF to: %s\n', outpath);
    end

end