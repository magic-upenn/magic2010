function handlerPoseExternal(data, name)
global RPOSE
  if isempty(data)
    return;
  end

  id = GetIdFromName(name);
  RPOSE{id} = MagicPoseSerializer('deserialize',data);
  fprintf('got pose of robot %d\n',id);
