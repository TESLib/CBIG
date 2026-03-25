function CBIG_LBC_cog_stability(input_Y0, input_Y2, outpath)
% CBIG_LBC_cog_stability(input_Y0, input_Y2, outpath)
%
% Compute and plot Spearman rank correlation (with 95% Fisher z confidence
% intervals) between age/sex-residualized cognitive scores at Year 0 and
% Year 2, as a measure of longitudinal cognitive stability.
%
% Input:
%     - input_Y0: (string)
%           Path to the Year 0 demographics and cognition CSV file
%           (DemoCog_Y0.csv). Age in column 6, sex in column 7,
%           8 cognitive scores in columns 15-22.
%
%     - input_Y2: (string)
%           Path to the Year 2 demographics and cognition CSV file
%           (DemoCog_Y2.csv). Same column structure as input_Y0.
%
%     - outpath: (string)
%           Full path to save the output figure (PDF).
%
% Output:
%     - A PDF figure saved to outpath showing per-measure Spearman rho
%       with 95% confidence intervals.
%
% Example:
%     CBIG_LBC_cog_stability('DemoCog_Y0.csv', 'DemoCog_Y2.csv', 'cog_stability.pdf')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% ===== Load data =====
CogMeasures_Y0 = readtable(input_Y0);
CogMeasures_Y2 = readtable(input_Y2);

%% ===== Extract variables =====
Age_Y0 = CogMeasures_Y0{:,6};
Age_Y2 = CogMeasures_Y2{:,6};
sex     = CogMeasures_Y0{:,7};

sex_dummy = zeros(size(sex));
sex_dummy(strcmp(sex,'F')) = 1;

Cog_Y0 = CogMeasures_Y0{:,15:22};   % N × 8
Cog_Y2 = CogMeasures_Y2{:,15:22};

[N,M] = size(Cog_Y0);

reg0 = [Age_Y0 sex_dummy];
reg2 = [Age_Y2 sex_dummy];

%% ===== Colors (per measure) =====
colors = [
    186/255,  74/255,  33/255   % RAVLT
    158/255,  66/255, 103/255   % LMT
    121/255, 153/255,  54/255   % PicVocab
    242/255, 196/255, 110/255   % Flanker
    180/255, 198/255, 230/255   % Pattern
    131/255, 164/255, 215/255   % Picture
    135/255, 125/255, 187/255   % Reading
     81/255,  69/255,  96/255   % PC1
];

%% ===== Compute Spearman rho and Fisher CIs =====
rho    = nan(M,1);
rho_CI = nan(2,M);

for t = 1:M
    LM0 = fitlm(reg0, Cog_Y0(:,t));
    LM2 = fitlm(reg2, Cog_Y2(:,t));

    r0 = LM0.Residuals.Raw;
    r2 = LM2.Residuals.Raw;

    rho(t) = corr(r0, r2, 'Type','Spearman');

    % Fisher z 95% CI
    z  = atanh(rho(t));
    se = 1 / sqrt(N - 3);
    z_CI = z + [-1.96 1.96] * se;
    rho_CI(:,t) = tanh(z_CI);
end

%% ===== Create figure (45 x 27 mm) =====
width  = 45/25.4;   % inches
height = 27/25.4;   % inches

fig = figure('Color','w', 'Units','inches', ...
             'Position',[1 1 width height]);
ax = axes(fig); hold(ax,'on');

%% ===== Axes settings =====
xlim(ax, [0.5 M+0.5]);
ylim(ax, [0 0.8]);

set(ax, 'YTick', 0:0.2:1, ...
        'YTickLabel', [], ...
        'TickDir', 'out');

set(ax, 'XTick', 1:M, ...
        'XTickLabel', [], ...
        'TickDir', 'out');

box(ax,'off');


%% ===== Plot CI first (black), then small circles with NO boundary =====
markerSize = 5;          % small clean circles
ciW        = 0.5;        % thin CI line
  

for t = 1:M

    % --- CI in background ---
    plot(ax, [t t], [rho_CI(1,t) rho_CI(2,t)], ...
         'Color','k', 'LineWidth', ciW);

    % --- Marker (foreground) ---
    scatter(ax, t, rho(t), markerSize, ...
        'Marker','o', ...
        'MarkerFaceColor', colors(t,:), ...
        'MarkerEdgeColor', 'none');
end

%% ===== Export as vector PDF with exact size =====
set(fig,'PaperUnits','inches');
set(fig,'PaperSize',[width height]);
set(fig,'PaperPosition',[0 0 width height]);

print(fig, outpath, '-dpdf', '-painters');
end