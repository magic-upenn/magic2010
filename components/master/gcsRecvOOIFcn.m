function gcsRecvOOIFcn(data, name)

if isempty(data)
  return
end

disp('got OOI message!');
msg = deserialize(data);
globalMapOOI(msg);
