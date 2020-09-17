
% import chlorophyll data (MODIS Aqua entire mission composite, 2002-2020)

% https://oceandata.sci.gsfc.nasa.gov/MODIS-Aqua/Mapped/Cumulative/9km/chl_ocx/
% https://oceandata.sci.gsfc.nasa.gov/ob/getfile/A20021852020121.L3m_CU_CHL_chl_ocx_9km.nc
% https://dx.doi.org/10.5067/AQUA/MODIS/L3M/CHL/2018

chl_nc = 'A20021852020121.L3m_CU_CHL_chl_ocx_9km.nc';

chl = ncread(chl_nc, 'chl_ocx');
lat = ncread(chl_nc, 'lat');
lon = ncread(chl_nc, 'lon');



% build 1-degree resampled CHL grid

lon_1deg = -180:179;
lat_1deg = -90:89;

[lon_1deg_grid, lat_1deg_grid] = meshgrid(lon_1deg, lat_1deg);

% flip to get chlorophyll with NW corner in top left
chl_rect = chl';

% resample to 1 degree grid
% ensure edges in original data matches 1 deg grid for no NaNs in interp2
lon(1)   = -180;
lon(end) =  180;
lat(1)   =   90;
lat(end) =  -90;
[longrid,latgrid] = meshgrid(lon,lat);

% use griddata instead of interp2 to properly resample with NaNs
% stackoverflow.com/questions/31729855
% land areas will be incorrect, but all sites are marine
chl_ok = ~isnan(chl_rect);
chl_1deg = griddata(longrid(chl_ok),latgrid(chl_ok), chl_rect(chl_ok), lon_1deg_grid,lat_1deg_grid);

% save to file
save('MODIS-Aqua_Mapped_Cumulative_1deg_chl_ocx.mat', 'chl', 'lat_1deg', 'lon_1deg');
