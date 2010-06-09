function gcsRecvPoseExternal(data, name)
global RPOSE GTRANSFORM GPOSE

if isempty(data)
  return;
end

id = GetIdFromName(name);
RPOSE{id} = MagicPoseSerializer('deserialize',data);

if isempty(GPOSE{id}),
  fprintf('Initializing pose of robot %d\n',id);
  
  GTRANSFORM{id}.dx = RPOSE{id}.x;
  GTRANSFORM{id}.dy = RPOSE{id}.y;
  GTRANSFORM{id}.dyaw = RPOSE{id}.yaw;
end

[GPOSE{id}.x, GPOSE{id}.y, GPOSE{id}.yaw] = rpos_to_gpos(id, ...
                                                  RPOSE{id}.x, ...
                                                  RPOSE{id}.y, ...
                                                  RPOSE{id}.yaw);
  
