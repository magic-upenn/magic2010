function [xc,yc,ac, imin] = pathClosestPoint(path, pos);
% [xc,yc,ac] = pathClosestPoint(path, pos);

xPos = pos(1);
yPos = pos(2);

nPath = size(path,1);
xPath = path(:,1);
yPath = path(:,2);
if (nPath == 1),
  xc = xPath;
  yc = yPath;
  ac = 0;
  return;
end

dxPath = diff(xPath);
dyPath = diff(yPath);
dPathSq = dxPath.^2 + dyPath.^2;
aPath = atan2(dyPath, dxPath);

dxProj = xPos - xPath(1:end-1);
dyProj = yPos - yPath(1:end-1);

cProj = (dxProj.*dxPath + dyProj.*dyPath)./max(dPathSq, eps);
% Clip projection to path segments:
cProj = min(max(cProj, 0), 1);

xPath0 = xPath(1:end-1) + cProj.*dxPath;
yPath0 = yPath(1:end-1) + cProj.*dyPath;

dProj = (xPos - xPath0).^2 + (yPos - yPath0).^2;
[ignore, imin] = min(dProj);

xc = xPath0(imin);
yc = yPath0(imin);
ac = aPath(imin);
