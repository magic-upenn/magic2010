function gcsRecvIncMapUpdateV(update,id)

global GPOSE GMAP GCS gcs_machine

fprintf(1,'got vertical map update from %d\n',id);

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

guiMsg.update = update;
guiMsg.id = id;
gcs_machine.ipcAPI('publish','IncV',serialize(guiMsg));

if ~isempty(GPOSE{id}) && any(id == GCS.sensor_ids)
  [xg, yg] = rpos_to_gpos(id, xm, ym);
  
  NotViewed = NotViewedByAnotherRobot(id, xg, yg);
  
  xg = xg(NotViewed);
  yg = yg(NotViewed);
  cm = cm(NotViewed);
  asgn(GMAP, 'cost', xg, yg, cm);
  
end
