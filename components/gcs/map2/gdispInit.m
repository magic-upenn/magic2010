function gdispInit

global MAGIC_CONSTANTS
global GDISP

if ~isempty(MAGIC_CONSTANTS),
  mapEastMin = MAGIC_CONSTANTS.mapEastMin;
  mapEastMax = MAGIC_CONSTANTS.mapEastMax;
  mapNorthMin = MAGIC_CONSTANTS.mapNorthMin;
  mapNorthMax = MAGIC_CONSTANTS.mapNorthMax;
  mapEastOffset = MAGIC_CONSTANTS.mapEastOffset;
  mapNorthOffset = MAGIC_CONSTANTS.mapNorthOffset;  
else
  [utmE, utmN, utmZone] = deg2utm(39.9524, -75.1915);
  mapEastMin = utmE-100.0;
  mapEastMax = utmE+100.0;
  mapNorthMin = utmN-100.0;
  mapNorthMax = utmN+100.0;  
  mapEastOffset = utmE;
  mapNorthOffset = utmN;  
end

GDISP.utmE0 = mapEastOffset;
GDISP.utmN0 = mapNorthOffset;

GDISP.utmEmin = mapEastMin;
GDISP.utmEmax = mapEastMax;
GDISP.utmNmin = mapNorthMin;
GDISP.utmNmax = mapNorthMax;

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
