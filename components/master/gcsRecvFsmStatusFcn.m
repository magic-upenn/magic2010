function gcsRecvFsmStatusFcn(data, name)

global GDISPLAY

if isempty(data)
  return;
end

id = GetIdFromName(name);
status = deserialize(data);
set(GDISPLAY.robotStatusText{id},'String',status);
