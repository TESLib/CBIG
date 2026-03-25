function CBIG_LBC_extract_combat_cognition( ...
    Y0_csv, Y2_csv, combat_csv, ...
    output_Y0, output_Y2, output_change)
% CBIG_LBC_extract_combat_cognition(Y0_csv, Y2_csv, combat_csv, output_Y0, output_Y2, output_change)
%
% Extract harmonized cognitive features from a stacked combat-corrected CSV,
% compute change scores (Y2 - Y0), and save updated Y0, Y2, and change tables.
%
% Input:
%     - Y0_csv: (string)
%           Path to input demo_cog_Y0 table (.csv) with demographics and
%           uncorrected Year 0 cognitive scores.
%
%     - Y2_csv: (string)
%           Path to input demo_cog_Y2 table (.csv) with demographics and
%           uncorrected Year 2 cognitive scores.
%
%     - combat_csv: (string)
%           Path to combat-corrected stacked Y0+Y2 table (.csv).
%
%     - output_Y0: (string)
%           Path to write updated Year 0 table (.csv).
%
%     - output_Y2: (string)
%           Path to write updated Year 2 table (.csv).
%
%     - output_change: (string)
%           Path to write computed cognitive change table (.csv).
%
% Output:
%     - Three .csv files written to output_Y0, output_Y2, and output_change.
%
% Example:
%     CBIG_LBC_extract_combat_cognition('Y0.csv', 'Y2.csv', 'combat.csv', ...
%         'Y0_out.csv', 'Y2_out.csv', 'change_out.csv')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

    % Load original Y0 and Y2 tables
    cog_Y0 = readtable(Y0_csv);
    cog_Y2 = readtable(Y2_csv);

    % Load stacked harmonized features
    cog_Y0Y2_combat = readtable(combat_csv);

    % Split harmonized data
    n_subjects = height(cog_Y0);
    Y0_combat = cog_Y0Y2_combat{1:n_subjects, 4:11};
    Y2_combat = cog_Y0Y2_combat{n_subjects+1:end, 4:11};
    change_combat = Y2_combat - Y0_combat;

    % Insert into tables
    cog_Y0{:,15:22} = Y0_combat;
    cog_Y2{:,15:22} = Y2_combat;

    cog_change = cog_Y2;
    cog_change{:,15:22} = change_combat;

    % Write outputs
    writetable(cog_Y0, output_Y0);
    writetable(cog_Y2, output_Y2);
    writetable(cog_change, output_change);
end
