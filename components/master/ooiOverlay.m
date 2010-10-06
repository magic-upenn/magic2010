function ooiOverlay()
global GDISPLAY OOI

for i=1:length(GDISPLAY.visualOOIText)
  delete(GDISPLAY.visualOOIText(i));
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
      th=1:0.1:2*pi;
      x=[-1 1 1 -1 -ones(1,length(th)-4); cos(th)];
      y=[-1 -1 1 1 ones(1,length(th)-4); sin(th)];
      c=[1 0 0; 0 0 0];
    case 3
      x=[-1 1 0];
      y=[-1 -1 1];
      c=[1 0 0];
    case 4
      th=1:0.1:2*pi;
      x=[-1 1 0 zeros(1,length(th)-3); cos(th)];
      y=[-1 -1 1 ones(1,length(th)-3); sin(th)];
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
    GDISPLAY.visualOOIText(i) = text(temp_x+2,temp_y,num2str(i),'FontSize',20);
    GDISPLAY.visualOOIOverlay(i) = patch(temp_x+x,temp_y+y,c,'ButtonDownFcn',@regionSelect,'Tag',strcat('o',num2str(i)));
  end
end

