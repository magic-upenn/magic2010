function gcsRecvUAVFcn(data,name)
global UAV_FEED OOI_PATH NC_PATH

if isempty(data)
  return
end

msg = deserialize(data);

fprintf(1,'got UAV feed\n');

UAV_FEED = msg;
for i=1:length(msg.point)
  if msg.point(i).type == 'M'
    id = msg.point(i).id+1;
    if length(OOI_PATH) < id || isempty(OOI_PATH(id))
      OOI_PATH(id).id = id;
      OOI_PATH(id).x = [];
      OOI_PATH(id).y = [];
    end
    OOI_PATH(id).x(end+1) = msg.point(i).easting;
    OOI_PATH(id).y(end+1) = msg.point(i).northing;
  else
    id = msg.point(i).id+1;
    if length(NC_PATH) < id || isempty(NC_PATH(id))
      NC_PATH(id).id = id;
      NC_PATH(id).x = [];
      NC_PATH(id).y = [];
    end
    NC_PATH(id).x(end+1) = msg.point(i).easting;
    NC_PATH(id).y(end+1) = msg.point(i).northing;
  end
end
UAVOverlay;
