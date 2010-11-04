function gdispMap(im, xim, yim)

global GDISP

x1 = xim - GDISP.utmE0;
y1 = yim - GDISP.utmN0;

set(GDISP.hMap, 'XData', x1, 'YData', y1, 'CData', im');
