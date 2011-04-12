function gcsRecvGlobalMapFcn(data, name)

global GMAP GTRANSFORM GPOSE GCS ROBOT_PATH

if isempty(data)
  return
end

try
  msg = deserialize(data);
catch
  disp('ERROR: map update fail!');
  return;
end

fprintf(1,'got global map\n');

GMAP = setdata(GMAP,'cost',double(msg.mapData));
GTRANSFORM = msg.GTRANSFORM;
GPOSE = msg.GPOSE;

for id=GCS.ids
  if ~isempty(GPOSE) && ~isempty(GPOSE{id}) && ~isempty(GPOSE{id}.x)
    ROBOT_PATH(id).x(end+1) = GPOSE{id}.x;
    ROBOT_PATH(id).y(end+1) = GPOSE{id}.y;
  end
end

