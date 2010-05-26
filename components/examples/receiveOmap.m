SetMagicPaths;

mapMsgName  = 'Robot2/ObstacleMap2D_map2d';
poseMsgName = 'Robot2/Pose';

host = '192.168.10.164';
ipcAPIConnect(host);
ipcAPISubscribe(mapMsgName);
ipcAPISubscribe(poseMsgName);

figure(1); clf(gcf);
hMap  = [];
hPose = [];

pose=[];
map=[];

while(1)
  msgs = ipcAPI('listen',10);
  len = length(msgs);
  if len > 0
    for i=1:len
      switch(msgs(i).name)
        case mapMsgName
          map = VisMap2DSerializer('deserialize',msgs(i).data);
          if isempty(hMap)
            hMap = imagesc(map.map.data'); hold on;
          else
            set(hMap,'cdata',map.map.data');
          end
          drawnow;
        case poseMsgName
          if isempty(map)
            continue;
          end
          pose = MagicPoseSerializer('deserialize',msgs(i).data);
          xi = (pose.x-map.xmin)/map.res;
          yi = (pose.y-map.ymin)/map.res;
          if isempty(hPose)
            hPose = plot(xi,yi,'r*'); hold off;
          else
            set(hPose,'xdata',xi,'ydata',yi);
          end
          drawnow;
      end
    end
  end
end