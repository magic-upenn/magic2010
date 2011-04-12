function gcsEntrySpread(ids)

global RPOSE RMAP

if nargin < 1,
  ids = [1:3];
end

for i = ids,
  RPOSE{i} = [];
  %  RMAP{i} = map2d(1200,1200,.15,'vlidar','hlidar');
  RMAP{i} = map2d(1200,1200,.15,'vlidar','hlidar','cost');
end

spreadInit;
for id = ids,
  RPOSE{id}.data = [];

  header = sprintf('robot%d_', id);
  spreadReceiveSetFcn([header 'Pose'], @recvPose);
  spreadReceiveSetFcn([header 'MapUpdateH'], @recvMapUpdateH);
  spreadReceiveSetFcn([header 'MapUpdateV'], @recvMapUpdateV);
end
