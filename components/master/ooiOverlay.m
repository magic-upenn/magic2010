function ooiOverlay()
global GDISPLAY OOI

GDISPLAY.lastRegionSelection = -1;

for i=1:length(GDISPLAY.visualOOIText)
  delete(GDISPLAY.visualOOIText(i));
end
for i=1:length(GDISPLAY.visualOOIOverlay)
  delete(GDISPLAY.visualOOIOverlay(i));
end
GDISPLAY.visualOOIText = [];
GDISPLAY.visualOOIOverlay = [];

if get(GDISPLAY.ooiOverlay,'Value')
  set(0,'CurrentFigure',GDISPLAY.hFigure);
  for i=1:length(OOI)

    switch OOI(i).type
    case 1
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[1 0 0];
    case 2
      th=0:0.1:2*pi;
      x=[-1 1 1 -1 -ones(1,length(th)-4); 0.5*cos(th)];
      y=[-1 -1 1 1 ones(1,length(th)-4); 0.5*sin(th)];
      c=[1 0 0; 0 0 0];
    case 3
      x=[-1 1 0];
      y=[-1 -1 1];
      c=[1 0 0];
    case 4
      th=0:0.1:2*pi;
      x=[-1 1 0 zeros(1,length(th)-3); 0.5*cos(th)];
      y=[-1 -1 1 ones(1,length(th)-3); 0.5*sin(th)];
      c=[1 0 0; 0 0 0];
    case 5
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[1 1 0];
    case 6
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[0 1 0];
    case 7
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[0 0 1];
    end

    temp_x = OOI(i).x;
    temp_y = OOI(i).y;
    GDISPLAY.visualOOIText(end+1) = text(temp_x+2,temp_y,num2str(i),'FontSize',20);
    for p=1:size(c,1)
      GDISPLAY.visualOOIOverlay(end+1) = patch(temp_x+x(p,:),temp_y+y(p,:),c(p,:),'ButtonDownFcn',@regionSelect,'Tag',strcat('o',num2str(i)));
    end
  end
end

