function gcsMapFitPose(id)

global RNODE

iterMax = 10;
gpsErrMax = 5.0;

node = RNODE{id};
if (~isfield(node,'gpsInitialized') || ~node.gpsInitialized),
  disp(sprintf('Cannot fit robot %d: GPS not initialized', id));
  return;
end

pF = node.pF;
pGps = node.pGps;
oL = node.oL;
gpsValid = node.gpsValid;
iBad = find(node.hlidarConf < 0.2);
nBad = length(iBad);

ivalid = find(gpsValid);

iterFit = 1;
while iterFit < iterMax,
  iterFit = iterFit+1;

  if (nBad < 1), break; end
  ifit = iBad(ceil(nBad*rand(1)));
  if (ifit == 1), continue; end;
  
  oL1 = oL(:,ifit);
  oL1min = oL1 - [.01 .01 3*pi/180]';
  oL1max = oL1 + [.01 .01 3*pi/180]';
  %  oL1min = oL1 - [.01 .01 1*pi/180]';
  %  oL1max = oL1 + [.01 .01 1*pi/180]';
  
  if (isempty(ivalid)), break; end
  %{
  gpsErr = pGps(:,ivalid) - pF(:,ivalid);
  gpsErrD = sqrt(sum(gpsErr(1:2,:).^2, 1));
  if (max(gpsErrD) < gpsErrMax), break; end;
  %}
  
  % Only fit future points:
  ifuture= ivalid(ivalid>=ifit);
  if isempty(ifuture), continue; end
  % Limit number of points to fit for efficiency
  if length(ifuture) > 100,
    ifuture = ifuture(1:100);
  end
  
  xf = o_p1p2(pF(:,ifit),pF(:,ifuture));
  xgps = o_p1p2(pF(:,ifit-1),pGps(:,ifuture));
  wfit = ones(1, length(ifuture));
  wheading = 100.0;

  ofit = o_fit(xf, xgps, wfit, wheading, ...
               oL1min, oL1max);
  dx = o_p1p2(pF(:,ifit), pF(:,ifit:end));
  pF1 = o_mult(pF(:,ifit-1), ofit);
  pF(:,ifit:end) = o_mult(pF1, dx);
end

RNODE{id}.pF = pF;
  
end