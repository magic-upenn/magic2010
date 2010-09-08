function mapfsmRecvPathFcn(data, name)

global MP PATH_DATA

if ~isempty(data)
  PATH_DATA.waypoints = deserialize(data);
  PATH_DATA.type = 0; %Waypoints
  MP.sm = setEvent(MP.sm, 'path');
end
