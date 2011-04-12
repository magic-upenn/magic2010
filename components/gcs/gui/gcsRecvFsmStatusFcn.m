function gcsRecvFsmStatusFcn(data, name)

global GDISPLAY

if isempty(data)
  return;
end

id = GetIdFromName(name);
msg = deserialize(data);
status = msg.status;
set(GDISPLAY.robotStatusText{id},'String',status);

GDISPLAY.servo{id} = msg.servo;
