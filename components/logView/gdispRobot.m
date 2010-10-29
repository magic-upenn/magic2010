function gdispRobot(id, utmE, utmN, utmA)
% UTM easting, northing, CCW angle relative to +East

global GDISP

scaleRobot = 3.0;
xRobot = scaleRobot*[-3.0 1.5 -3.0 -3.0];
yRobot = scaleRobot*[-1.0 0  1.0 -1.0];

trans = [cos(utmA)  -sin(utmA) utmE-GDISP.utmE0;
         sin(utmA)  cos(utmA) utmN-GDISP.utmN0;
         0 0 1];

pRobot = trans*[xRobot; yRobot; ones(size(xRobot))];
pX = utmE - GDISP.utmE0;
pY = utmN - GDISP.utmN0;

if isempty(GDISP.hRobot{id}),
  hold on;
  GDISP.hRobot{id}.hFill = fill(pRobot(1,:), pRobot(2,:), 'g');
  GDISP.hRobot{id}.hText = text(pX, pY, num2str(id));
  set(GDISP.hRobot{id}.hText, 'HorizontalAlignment', 'center', ...
                    'FontSize', 14);
  hold off;
else
  set(GDISP.hRobot{id}.hFill, 'XData', pRobot(1,:), ...
                    'YData', pRobot(2,:));
  set(GDISP.hRobot{id}.hText, 'Position', [pX pY]);
  end


