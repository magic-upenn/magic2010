function gmapInit

global GMAP

%GMAP = map2d(1400, 1500, 0.2, 'hlidar', 'vlidar', 'cost');

[utmE, utmN, utmZone] = deg2utm(39.9524, -75.1915);
GMAP.x = utmE + [-100 150];
GMAP.y = utmN + [-100 200];

resolution = 0.10;
nx = (GMAP.x(end)-GMAP.x(1))/resolution + 1;
ny = (GMAP.y(end)-GMAP.y(1))/resolution + 1;

GMAP.im = zeros(nx, ny);


