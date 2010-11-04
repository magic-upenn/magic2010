function gcsRecvGlobalMapFcn(data, name)

global GMAP GTRANSFORM GPOSE GCS MAGIC_CONSTANTS

if isempty(data)
  return
end

msg = deserialize(data);

fprintf(1,'got global map\n');

GMAP = setdata(GMAP,'cost',msg.mapData);
GTRANSFORM = msg.GTRANSFORM;
GPOSE = msg.GPOSE;
%for id=GCS.ids
  %GPOSE{id}.x = GPOSE{id}.x-MAGIC_CONSTANTS.mapEastOffset;
  %GPOSE{id}.y = GPOSE{id}.y-MAGIC_CONSTANTS.mapNorthOffset;
%end

%for i=
%ROBOT_PATH(id).x(end+1) = GPOSE{id}.x;
%ROBOT_PATH(id).y(end+1) = GPOSE{id}.y;

