function UAVOverlay()
global GDISPLAY UAV_FEED MAGIC_CONSTANTS

for i=1:length(GDISPLAY.visualUAVText)
  delete(GDISPLAY.visualUAVText(i));
end
for i=1:length(GDISPLAY.visualUAVOverlay)
  delete(GDISPLAY.visualUAVOverlay(i));
end
GDISPLAY.visualUAVText = [];
GDISPLAY.visualUAVOverlay = [];

if get(GDISPLAY.UAVOverlay,'Value')
  set(0,'CurrentFigure',GDISPLAY.hFigure);
  for i=1:length(UAV_FEED.point)

    %{
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
      th = ([0 120 240]+90)*pi/180;
      x=sqrt(2)*cos(th);
      y=sqrt(2)*sin(th);
      c=[1 0 0];
    case 4
      th=0:0.1:2*pi;
      th2 = ([0 120 240]+90)*pi/180;
      x=[sqrt(2)*cos(th2) zeros(1,length(th)-3); 0.5*cos(th)];
      y=[sqrt(2)*sin(th2) sqrt(2)*ones(1,length(th)-3); 0.5*sin(th)];
      c=[1 0 0; 0 0 0];
    case 5
      th = ([0 120 240]+90)*pi/180;
      x=sqrt(2)*cos(th);
      y=sqrt(2)*sin(th);
      c=[1 0 0];
    case 6
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[1 1 0];
    case 7
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[0 1 0];
    case 8
      x=[-1 1 1 -1];
      y=[-1 -1 1 1];
      c=[0 0 1];
    end
    %}

    if(UAV_FEED.point(i).easting <= MAGIC_CONSTANTS.mapEastMax && ...
       UAV_FEED.point(i).easting >= MAGIC_CONSTANTS.mapEastMin && ...
       UAV_FEED.point(i).northing <= MAGIC_CONSTANTS.mapNorthMax && ...
       UAV_FEED.point(i).northing >= MAGIC_CONSTANTS.mapNorthMin)
      temp_x = UAV_FEED.point(i).easting - MAGIC_CONSTANTS.mapEastOffset;
      temp_y = UAV_FEED.point(i).northing - MAGIC_CONSTANTS.mapNorthOffset;
      GDISPLAY.visualUAVText(end+1) = text(temp_x,temp_y,UAV_FEED.point(i).type,'FontSize',20);
      %GDISPLAY.visualUAVText(end+1) = text(temp_x+2,temp_y,num2str(i),'FontSize',20);
      %for p=1:size(c,1)
        %GDISPLAY.visualUAVOverlay(end+1) = patch(temp_x+x(p,:),temp_y+y(p,:),c(p,:),'ButtonDownFcn',@regionSelect,'Tag',strcat('o',num2str(i)));
      %end
    end
  end
end

