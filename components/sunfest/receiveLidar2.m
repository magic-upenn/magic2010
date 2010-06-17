clear all;
global LIDAR0;

SetMagicPaths;

id = 2;
setenv('ROBOT_ID',sprintf('%d',id));
lidar0MsgName = GetMsgName('Lidar0');

host = '192.168.10.102';
ipcAPIConnect(host);
ipcAPISubscribe(lidar0MsgName);

lidar0Init;

robotRadius=0.4;
dangerRadius=1;
v=0; w=0; dv=0.05; dw=0.05; vmax=1.27;

dangerZone = [linspace(0,2*pi,50); dangerRadius*ones(1,50)];
robot = [linspace(0,2*pi,50); robotRadius*ones(1,50)];
%robot = [pi/4*[1:2:9]; s/2^.5*ones(1,5)];

clf(gcf);
hLidar = polar(0,10,'b.'); hold on;
hDanger = polar(0,0,'r.');
polar(dangerZone(1,:),dangerZone(2,:),'g');
polar(robot(1,:),robot(2,:),'r');

hold off;

while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      lidarScan = MagicLidarScanSerializer('deserialize',msgs(i).data);
      lidarData = double([linspace(lidarScan.startAngle,lidarScan.stopAngle,length(lidarScan.ranges))+pi/2; lidarScan.ranges]);
      lidarData(:,lidarData(2,:)<=0.002)=[];
      
      lidaroff = 0.137;
      [xshift yshift] = pol2cart(lidarData(1,:),lidarData(2,:));
      yshift = yshift + lidaroff;
      [tshift pshift] = cart2pol(xshift,yshift);
      lidarData = [tshift; pshift];
      
      dangerData=lidarData(:,lidarData(2,:)<=1);
      lidarData(:,lidarData(2,:)<=1)=[];

      c = getch();
  
      if ~isempty(c)
        switch c
          case 'w'
            v=v+dv;
          case 's'
            v=v-dv;
          case 'a'
            w=w+dw;
          case 'd'
            w=w-dw;
        end
      end
      
      vlimit=vmax;
      if ~isempty(dangerData)
          vlimit = vmax*(min(dangerData(2,:))-robotRadius)/(dangerRadius-robotRadius);
          if vlimit<0
              vlimit=0;    
          end
      end
      
      if v>vlimit
          SetVelocity(vlimit,w);
      else
          SetVelocity(v,w);
      end
      
      fprintf(1,'v=%f w=%f\n',v,w);
      
      set(hLidar,'xdata',lidarData(2,:).*cos(lidarData(1,:)),'ydata',lidarData(2,:).*sin(lidarData(1,:)));
      set(hDanger,'xdata',dangerData(2,:).*cos(dangerData(1,:)),'ydata',dangerData(2,:).*sin(dangerData(1,:)));
               
      drawnow;
      
    end
  end
end