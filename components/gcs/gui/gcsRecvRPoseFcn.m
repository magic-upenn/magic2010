function gcsRecvRPoseFcn(data, name)
global RPOSE GTRANSFORM GPOSE ROBOT_PATH GCS

if isempty(data)
  return;
end

msg = deserialize(data);

id = msg.id;
if ~any(id==GCS.ids)
  return;
end
%RPOSE{id} = MagicPoseSerializer('deserialize',data);
RPOSE{id} = msg.update;

if isempty(GPOSE{id}),
  fprintf('Initializing pose of robot %d\n',id);
  
  GTRANSFORM{id}.dx = RPOSE{id}.x;
  GTRANSFORM{id}.dy = RPOSE{id}.y;
  GTRANSFORM{id}.dyaw = RPOSE{id}.yaw;
end

%[GPOSE{id}.x, GPOSE{id}.y, GPOSE{id}.yaw] = rpos_to_gpos(id, ...
                                                  %RPOSE{id}.x, ...
                                                  %RPOSE{id}.y, ...
                                                  %RPOSE{id}.yaw);
  
%ROBOT_PATH(id).x(end+1) = GPOSE{id}.x;
%ROBOT_PATH(id).y(end+1) = GPOSE{id}.y;

