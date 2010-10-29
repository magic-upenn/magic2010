function gdispInit

global GDISP

[utmE, utmN, utmZone] = deg2utm(39.9524, -75.1915);
GDISP.utmE0 = utmE;
GDISP.utmN0 = utmN;

GDISP.utmEmin = utmE-100.0;
GDISP.utmEmax = utmE+150.0;
GDISP.utmNmin = utmN-50.0;
GDISP.utmNmax = utmN+200.0;

if isfield(GDISP, 'hFig'),
  clf(GDISP.hFig);
else
  GDISP.hFig = figure;
end

set(GDISP.hFig,'NumberTitle','off','Name','Global', ...
               'Position',[0 500 400 400]);

% Map
GDISP.hMap = imagesc([0 1], [0 1], zeros(2,2), [-100 100]);
axis xy;

% Robots
for iRobot = 1:9,
  GDISP.hRobot{iRobot} = [];
end

xlabel('Easting');
ylabel('Northing');
axis equal;
axis([[GDISP.utmEmin GDISP.utmEmax]-GDISP.utmE0 ...
      [GDISP.utmNmin GDISP.utmNmax]-GDISP.utmN0]);


end
