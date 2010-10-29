function gmapInit

global GMAP

GMAP = map2d(1400, 1500, 0.2, 'hlidar', 'vlidar', 'cost');

[utmE, utmN, utmZone] = deg2utm(39.9524, -75.1915);
GMAP = shift(GMAP, utmE, utmN+100);
