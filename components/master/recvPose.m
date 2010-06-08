function recvPose(data, name)
global RPOSE

if isempty(data)
  return;
end

id = sscanf(name, 'robot%d_');
RPOSE{id}.data = deserialize(data);
fprintf('got pose of robot %d\n',id);
