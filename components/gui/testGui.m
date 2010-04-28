figure(1)

nPoints = 10;
xs = 10*rand(nPoints,1);
ys = 10*rand(nPoints,1);

%hPlot = plot(xs,ys,'.');
hPlot = imagesc(rand(nPoints));
drawnow;

set(gcf,'WindowButtonUpFcn',@mouseClickCallback);