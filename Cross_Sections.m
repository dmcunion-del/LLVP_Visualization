clear; close all
% This version subtracts votes for fast from votes for slow to create a
% full picture, slightly different from treating each individually

%A bud reduced what should have been majority to vote level 4 so I've
%carried that over for consistency. 
load Vote_Fast.mat 
load Vote_1_perc.mat
vote_count(vote_count <4) = 0;
vote_count_fast(vote_count_fast <4) =0;
plot_vote = vote_count - vote_count_fast;
lon_orig = linspace(0, 360, 361);
lon_shifted = wrapTo180(lon_orig);
[lon_sorted, sortIdx] = sort(lon_shifted);

% Reorder plot_vote along the longitude
plot_vote = plot_vote(:, sortIdx, :);
[lons2,lats2] = meshgrid(linspace(-180,180,361),linspace(-90,90,181)); 
lat = linspace(-90, 90, 181);
lon = linspace(-180, 180, 361);
dep = linspace(0, -2850, 57);
prompt = {'Start Lat', 'Start Lon:', 'End Lat', 'End Lon','Resolution?'};
dlgtitle = 'Cross Section Path';
dims = [1 35];
definput = {'-26', '2','19', '65' , '1000'};

% Open the GUI window for user input
answer = inputdlg(prompt, dlgtitle, dims, definput);

if ~isempty(answer)
    lat1 = str2double(answer{1});
    lon1 = str2double(answer{2});
    lat2 = str2double(answer{3});
    lon2 = str2double(answer{4});
    nPts = str2double(answer{5});
end
clear answer
%calculate great circle path between points

[latPath, lonPath] = track2('gc', lat1, lon1, lat2, lon2, [], 'degrees', nPts);
lonPath = wrapTo180(lonPath);

% Flip depth and data so coordinates are ascending (-2850 to 0)
depAsc = flip(dep);
dataAsc = flip(plot_vote, 3);

F = griddedInterpolant({lat, lon, depAsc}, dataAsc, 'nearest', 'none');
[qLat, qDep] = ndgrid(latPath, depAsc);
qLon = repmat(lonPath(:), 1, numel(depAsc));

% Cross-section matrix: [57 depths x nPts along path]
crossSec = F(qLat, qLon, qDep)';

% Distance along great circle (km)
distKm = deg2km(distance('gc', lat1, lon1, latPath, lonPath));
% Stack both colormaps into a single 21-row matrix
votecolors = [...
    0 0 1; % -10
    0 0 1; %-9
    0 0 1; %-8
    0 1 1; %-7
    0 1 1; %-6
    0 1 1; %-5
    0 1 1; %-4
    1 1 1; %-3
    1 1 1; %-2
    1 1 1; %-1
    1 1 1; %0
    1 1 1; %1
    1 1 1; %2
    1 1 1; %3
    1 0.5 0 ; %4
    1 0.5 0 ;  %5
    1 0.5 0;  %6
    1 0.5 0;  %7
    1 0 0; % 8
    1 0 0; %9
    1 0 0; %10
    ];
% Plot vertical cross section

pad = 15;
lonMin = max(-180, min(lonPath) - pad);
lonMax = min(180,  max(lonPath) + pad);
latMin = max(-85,  min(latPath) - pad); % Clamped to -85/85 for Lambert projection stability
latMax = min(85,   max(latPath) + pad);

figure; hold on;
m_proj('lambert', 'long', [lonMin lonMax], 'lat', [latMin latMax]);
m_pcolor(lons2, lats2, plot_vote(:,:,57));
shading flat;
m_coast('color', 'k', 'linewidth', 1);
m_grid('fancy');
colormap(votecolors);
clim([-10 10]);

% Plot the great-circle path and endpoints
m_line(lonPath, latPath, 'color', 'k', 'linewidth', 2);
m_line(lon1, lat1, 'marker', 'o', 'markersize', 14, 'color', 'k', 'markerfacecolor', 'g');
m_line(lon2, lat2, 'marker', 'o', 'markersize', 8, 'color', 'k', 'markerfacecolor', 'g');

% Labels and colorbar
title('2890km Depth Reveal, Spiral, gypsum, SGlobe, SEMUCB, GLAD-35, LOWE, TX2019, Savani, ME16');
cb = colorbar;
xlabel(cb, 'Votes for 0.5% fast subtracted from 1% slow');

R_earth = 6371; % Earth radius in km

%  Angular distance along great circle
arcDeg = distance('gc', lat1, lon1, latPath, lonPath); % 0 to total arc length (deg)
arcCentered = deg2rad(arcDeg - max(arcDeg)/2);         % Center wedge at 12 o'clock (0 rad)

% Radial coordinates from Earth's center (km)
r = R_earth + depAsc(:); % 57 x 1 vector (3521 km at CMB to 6371 km at surface)

% polar-to-Cartesian grid
[THETA, R] = meshgrid(arcCentered, r);
X = R .* sin(THETA);
Y = R .* cos(THETA);

% Plot curved spherical cross section
figure; hold on;
pcolor(X, Y, crossSec);
shading flat;
axis equal off;
colormap(votecolors);
clim([-10 10]);

% Add surface arc, CMB arc, boundary lines
thetaFine = linspace(min(arcCentered), max(arcCentered), 200);
plot(R_earth * sin(thetaFine), R_earth * cos(thetaFine), 'k', 'LineWidth', 1.5);             % Surface (0 km)
plot((R_earth - 2850) * sin(thetaFine), (R_earth - 2850) * cos(thetaFine), 'k', 'LineWidth', 1.5); % CMB (-2850 km)
plot([X(1,1) X(end,1)], [Y(1,1) Y(end,1)], 'k', 'LineWidth', 1.2);                         % Left edge
plot([X(1,end) X(end,end)], [Y(1,end) Y(end,end)], 'k', 'LineWidth', 1.2);                 % Right edge

% depth reference arcs
for d = [410, 660, 2700]
    plot((R_earth - d) * sin(thetaFine), (R_earth - d) * cos(thetaFine), 'k--', 'LineWidth', 0.8);
end

text(X(end,1), Y(end,1) + 150, sprintf('(%.1f°, %.1f°)', lat1, lon1), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(X(end,end), Y(end,end) + 150, sprintf('(%.1f°, %.1f°)', lat2, lon2), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');

cb = colorbar('southoutside');
xlabel(cb, 'Votes for 0.5% fast subtracted from 1% slow');
title(sprintf('Mantle Cross Section: (%.1f°, %.1f°) to (%.1f°, %.1f°)', lat1, lon1, lat2, lon2));
