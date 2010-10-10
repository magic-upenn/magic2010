function gcsRecvIncMapUpdateV(data, name)

global RMAP
global GPOSE GMAP GCS

if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got vertical map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'vlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);

if ~isempty(GPOSE{id}) && any(id == GCS.sensor_ids)
  [xg, yg] = rpos_to_gpos(id, xm, ym);
  
  NotViewed = NotViewedByAnotherRobot(id, xg, yg);
  
  xg = xg(NotViewed);
  yg = yg(NotViewed);
  cm = cm(NotViewed);
  asgn(GMAP, 'cost', xg, yg, cm);
  
end
