function globalMapOOI(msg)

global GDISPLAY GMAP OOI GCS GPOSE MAGIC_CONSTANTS OOI_AVOID_MASKS CAND_OOI

if nargin > 0
  [xp yp] = rpos_to_gpos(msg.id, msg.x, msg.y);
  id = msg.id;
  %xp = GPOSE{id}.x + msg.x*cos(GPOSE{id}.yaw) - msg.y*sin(GPOSE{id}.yaw);
  %yp = GPOSE{id}.y + msg.x*sin(GPOSE{id}.yaw) + msg.y*cos(GPOSE{id}.yaw);
  serial = msg.ser;
  type = msg.type;
  shirtNumber = msg.shirtNumber;
else
  [xp, yp] = ginput(1);
  id = -1;
  serial = -1;
  type = GDISPLAY.selectedOOI;
  shirtNumber = -1;
end

if ~isempty(xp),
  if type == 9 %Candidate OOI
    CAND_OOI.x = xp;
    CAND_OOI.y = yp;
    candOOIOverlay();
  else
    disp('adding ooi...');
    OOI(end+1).type = type;
    OOI(end).x = xp;
    OOI(end).y = yp;
    OOI(end).serial = serial;
    OOI(end).shirtNumber = shirtNumber;
    OOI(end).ts = gettime;
    if nargin > 0
      OOI(end).rel_x = msg.x;
      OOI(end).rel_y = msg.y;
      OOI(end).robot_id = id;
    else
      OOI(end).rel_x = [];
      OOI(end).rel_y = [];
      OOI(end).robot_id = [];
    end

    set(GDISPLAY.ooiList,'String',1:length(OOI));
    ooiOverlay();
    
    if OOI(end).type == 1
      goToOOI(xp,yp,MAGIC_CONSTANTS.ooi_range,OOI_AVOID_MASKS.ooi,GCS.disruptor_ids(GCS.disruptor_ids~=id),serial);
    elseif OOI(end).type == 3
      goToOOI(xp,yp,MAGIC_CONSTANTS.poi_range,OOI_AVOID_MASKS.poi,GCS.sensor_ids(GCS.sensor_ids~=id),serial);
    elseif OOI(end).type == 5
      goToOOI(xp,yp,MAGIC_CONSTANTS.poi_range,OOI_AVOID_MASKS.poi,[],serial);
    end
  end
end
