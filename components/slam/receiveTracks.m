function receiveTracks

SetMagicPaths;

ids=[2];

masterConnectRobots(ids);

messages = {'VelTracks'};
handles  = {@VelTracksMsgHandler};
          
queueLengths = [5];

%subscribe
masterSubscribeRobots(messages,handles,queueLengths);

while(1)
  masterReceiveFromRobots(); %will return without blocking
  pause(0.1);
end


function VelTracksMsgHandler(data,name)

tracks = deserialize(data)


hVels = [];

if length(tracks.xs) > 0
  hVels = quiver(tracks.xs,tracks.ys,tracks.vxs,tracks.vys,0,'g');
  axis([-10 10 -10 10]);
  drawnow;disp('got tracks');
else
  delete(hVels);
  drawnow;
end