% If 'MODIS-Aqua_Mapped_Cumulative_1deg_chl_ocx.mat' doesn't exist,
% run 'convertMODISaqua.m' first

% get CHL at each site

load('MODIS-Aqua_Mapped_Cumulative_1deg_chl_ocx.mat')
sites_tbl = readtable('../../data/sites.csv');

% lookup containing 'cell' of lat/lon - i.e. the integer part
% 
% data cell:       c1     c2        c359   c360
%               |------|------ ... ------|------|
% long (deg): -180   -179               179    180
% cell index:   1      2                360
%
% cell c1   (index 1)   covers -180 >= lon < -179
% cell c360 (index 360) covers  179 >= lon <  180
% 
% 179.9E (E side of Date line) should fall in last (360th) cell of chl_1deg
% floor(179.9+181) = 360
% chl data near N pole should fall in last (180th) lat 'cell'
% floor(89.9+91) = 180

sites_lat_int = floor(sites_tbl.lat+91);
sites_lon_int = floor(sites_tbl.lon+181);

% use linear indexing 
% mathworks.com/company/newsletters/articles/matrix-indexing-in-matlab
ind = sub2ind(size(chl_1deg), sites_lat_int, sites_lon_int);
sites_chl = round(chl_1deg(ind),4);

% add column to table
if (ismember('chl_a_modern', sites_tbl.Properties.VariableNames))
    sites_tbl.chl_a_modern = sites_chl;
else
    sites_tbl = addvars(sites_tbl, sites_chl, 'NewVariableNames', 'chl_a_modern');
end

writetable(sites_tbl(:, ["site_name", "chl_a_modern"]), '../../data/env.csv')
