function gcsMapFitPose(id)

global RNODE RPOSE

iterMax = 5;
gpsErrMax = 5.0;

node = RNODE{id};
if (~isfield(node,'gpsInitialized') || ~node.gpsInitialized),
  disp(sprintf('gcsMapFitPose: robot %d: GPS %d sat, %.2f hdop', ...
               id, RPOSE{id}.gps.numSat, RPOSE{id}.gps.hdop));
  return;
end

pF = node.pF;
pGps = node.pGps;
oL = node.oL;
gpsValid = node.gpsValid;
speed = node.speed;
iBad = find(node.hlidarConf < 0.1);
nBadInitial = 10;
iBad = [iBad 2:min(node.n,nBadInitial)];  % also fit initial points

nBad = length(iBad);

ivalid = find(gpsValid);
if (isempty(ivalid)), return; end

iterFit = 0;
while iterFit < iterMax,
  iterFit = iterFit+1;

  if (nBad < 1), break; end
  ifit = iBad(ceil(nBad*rand(1)));
  
  oL1 = oL(:,ifit);
  oL1xErr = .01;
  oL1yErr = .01;
  oL1aErr = 3*pi/180*exp(-node.hlidarConf(ifit)/.3);
  if (ifit < nBadInitial),
    oL1xErr = .05;
    oL1yErr = .05;
  end
  oL1min = oL1 - [oL1xErr oL1yErr oL1aErr]';
  oL1max = oL1 + [oL1xErr oL1yErr oL1aErr]';
  
  %{
  gpsErr = pGps(:,ivalid) - pF(:,ivalid);
  gpsErrD = sqrt(sum(gpsErr(1:2,:).^2, 1));
  if (max(gpsErrD) < gpsErrMax), break; end;
  %}
  
  % Only fit future points:
  ifuture= ivalid(ivalid>=ifit);
  if isempty(ifuture), continue; end
  if (length(ifuture) < 30), continue; end
  % Limit number of points to fit for efficiency
  %{
  if length(ifuture) > 100,
    ifuture = ifuture(1:100);
  end
  %}

  if (ifit == 1),
    continue;
  else
    pFprev = pF(:,ifit-1);
  end
  xf = o_p1p2(pF(:,ifit),pF(:,ifuture));
  xgps = o_p1p2(pFprev,pGps(:,ifuture));

  dx = sqrt(sum((xf(1:2,:)-xgps(1:2,:)).^2, 1));
  wfit = 1./(max(dx, 3.0).^0.5);

  %wheading = 2*speed(ifuture);
  wheading = 1;

  ofit = o_fit(xf, xgps, wfit, wheading, ...
               oL1min, oL1max);
  dx = o_p1p2(pF(:,ifit), pF(:,ifit:end));
  pF1 = o_mult(pFprev, ofit);
  pF(:,ifit:end) = o_mult(pF1, dx);
end

RNODE{id}.pF = pF;
%RNODE{id}.pF = RPOSE{id}.pL
