function gcsRecvGlobalMapFcn(data, name)

global GMAP GTRANSFORM GPOSE

if isempty(data)
  return
end

msg = deserialize(data);

fprintf(1,'got global map\n');

GMAP = setdata(GMAP,'cost',msg.mapData);
GTRANSFORM = msg.GTRANSFORM;
GPOSE = msg.GPOSE;

