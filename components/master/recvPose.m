function recvPose(data, name)
global RPOSE

if isempty(data)
  return;
end

id = sscanf(name, 'robot%d_');
RPOSE{id} = deserialize(data);
RPOSE{id}.heading = RPOSE{id}.yaw;

fprintf('got pose of robot %d\n',id);
