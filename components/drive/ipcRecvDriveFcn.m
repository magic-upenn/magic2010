function ipcRecvDriveFcn(data, name)

global DRIVE

if ~isempty(data)
  DRIVE = deserialize(data);
end
