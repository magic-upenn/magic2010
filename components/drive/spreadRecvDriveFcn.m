function spreadRecvDriveFcn(data, name);

global DRIVE

if isempty(data), return; end

DRIVE = deserialize(data);
