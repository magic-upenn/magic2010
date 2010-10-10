function gcsRecvOOIFcn(data, name)
global GCS

if isempty(data)
  return
end

disp('got OOI message!');
msg = deserialize(data);

if ~any(GCS.ids == msg.id)
  return
end

switch msg.type
case 'RedBarrel'
  msg.type = 1;
case 'MovingPOI'
  msg.type = 3;
case 'StationaryPOI'
  msg.type = 5;
case 'YellowBarrel'
  msg.type = 5;
case 'Doorway'
  msg.type = 6;
case 'Car'
  msg.type = 7;
end

msg.id = double(msg.id);
msg.x = double(msg.x);
msg.y = double(msg.y);

globalMapOOI(msg);
