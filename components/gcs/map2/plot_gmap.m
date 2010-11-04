function plot_gmap(id)
  
global RNODE
global GMAP

gmapInit;
node = RNODE{id};

gdispInit;
for i = 1:node.n,
  pF1 = node.pF(:,i);

  gdispRobot(id, pF1);
  gmapAdd(id, i);
  gdispMap(GMAP.im, GMAP.x, GMAP.y);
  drawnow;
end
