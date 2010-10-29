function gcsRecvUAVFcn(data,name)
global UAV_FEED

if isempty(data)
  return
end

msg = deserialize(data);

fprintf(1,'got UAV feed\n');

UAV_FEED = msg;
