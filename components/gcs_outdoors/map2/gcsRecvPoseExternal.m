function gcsRecvPoseExternal(data,id)
global RPOSE GTRANSFORM GPOSE ROBOT_PATH gcs_machine

RPOSE{id} = data;

guiMsg.update = data;
guiMsg.id = id;
gcs_machine.ipcAPI('publish','RPose',serialize(guiMsg));

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

