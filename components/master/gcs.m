function gcs(log_file)
more off;

global INIT_LOG RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI
INIT_LOG = nargin >= 1;
if INIT_LOG
  load(log_file);
end

%%%  gcs stuff
global gcs_machine Robots GCS MAGIC_CONSTANTS
count =0;

gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
ipcReceiveSetFcn('Global_Planner_TRAJ',@GPTRAJHandler,gcs_machine.ipcAPI,1);
gcs_machine.ipcAPI('define','Global_Planner_DATA',  MagicGP_DATASerializer('getFormat'));
ipcReceiveSetFcn('OOI_Msg',@gcsRecvOOIFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('OOI_Done_Msg',@gcsRecvOOIDoneFcn,gcs_machine.ipcAPI,1);

tUpdate = 0.1;

GCS.disruptor_ids = [6];
GCS.sensor_ids = [7];
ids = [GCS.disruptor_ids GCS.sensor_ids];

MAGIC_CONSTANTS.ooi_range = 3.5;
MAGIC_CONSTANTS.poi_range = 6.0;

for id = ids,
  Robots(id).traj.handle = -1;
end

initExploreTemplates();
gcsEntryIPC(ids)
mapDisplay('entry');
% GCS_GUI;

while 1,
    count = count +1;
  pause(tUpdate);
  gcsUpdateIPC;
  mapDisplay('update');
  if (mod(count, 30)==0)
      sendMapToExploration;
  end
% UpdateGoals;
end

end

