function ipcRecvDriveFcn(data, name)

global MP

if ~isempty(data)
  MP.sm = setEvent(MP.sm, deserialize(data));
end
