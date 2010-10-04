function gcs(log_file)
more off;

global INIT_LOG RPOSE RMAP GPOSE GMAP GTRANSFORM
INIT_LOG = nargin >= 1;
if INIT_LOG
  load(log_file);
end

%%%  gcs stuff
global gcs_machine Robots PLAN_DEBUG
PLAN_DEBUG = 0;
gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
%ipcReceiveSetFcn('Global_Planner_Trajectory',@GPTRAJHandler,gcs_machine.ipcAPI,15);
ipcReceiveSetFcn('Global_Planner_TRAJ',@GPTRAJHandler,gcs_machine.ipcAPI,1);
count =0;
%gcs_machine.ipcAPI('define','Global_Planner_All_Pose_Update',  MagicGP_ALL_POSE_UPDATESerializer('getFormat'));
%gcs_machine.ipcAPI('define','Global_Planner_MAGIC_MAP',  MagicGP_MAGIC_MAPSerializer('getFormat'));
gcs_machine.ipcAPI('define','Global_Planner_DATA',  MagicGP_DATASerializer('getFormat'));

tUpdate = 0.1;
%ids = [1 3];
ids = [3];
%ids = [1 2 3];

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

