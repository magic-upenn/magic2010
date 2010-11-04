function plot_paths(id)
  
global RNODE

node = RNODE{id};

if (~node.gpsInitialized), return, end

pF = node.pF;
pGps = node.pGps;
gpsValid = find(node.gpsValid);

plot(pF(1,:),pF(2,:),'b.-',...
     pGps(1,:),pGps(2,:),'g.');
hold on;
plot([pF(1,gpsValid);pGps(1,gpsValid)],[pF(2,gpsValid);pGps(2,gpsValid)], 'k--');
hold off
drawnow;
