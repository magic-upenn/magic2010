function gdispMap(map)

global GDISP

x1 = x(map) - GDISP.utmE0;
y1 = y(map) - GDISP.utmN0;
c1 = getdata(map, 'cost')';

set(GDISP.hMap, 'XData', x1, 'YData', y1, 'CData', c1);
