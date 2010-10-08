function globalMapOOI(msg)

global GDISPLAY GMAP OOI GCS GPOSE

if nargin > 0
  [xp yp] = rpos_to_gpos(msg.id, msg.x, msg.y);
  id = msg.id;
  %xp = GPOSE{id}.x + msg.x*cos(GPOSE{id}.yaw) - msg.y*sin(GPOSE{id}.yaw);
  %yp = GPOSE{id}.y + msg.x*sin(GPOSE{id}.yaw) + msg.y*cos(GPOSE{id}.yaw);
  serial = msg.ser;
  type = msg.type;
else
  [xp, yp] = ginput(1);
  id = -1;
  serial = -1;
  type = GDISPLAY.selectedOOI;
end

if ~isempty(xp),
  disp('adding ooi...');
  OOI(end+1).type = type;
  OOI(end).x = xp;
  OOI(end).y = yp;
  OOI(end).serial = serial;

  set(GDISPLAY.ooiList,'String',1:length(OOI));
  ooiOverlay();
  
  if OOI(end).type == 1
    goToOOI(xp,yp,3.5,GCS.disruptor_ids(GCS.disruptor_ids~=id));
  elseif OOI(end).type == 3
    goToOOI(xp,yp,6,GCS.sensor_ids(GCS.sensor_ids~=id));
  end
end
