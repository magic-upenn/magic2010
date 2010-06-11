function gcs
more off;

%%%  gcs stuff
global gcs_machine Robots
gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
ipcReceiveSetFcn('Global_Planner_Trajectory',@GPTRAJHandler,gcs_machine.ipcAPI,15);
count =0;
gcs_machine.ipcAPI('define','Global_Planner_All_Pose_Update',  MagicGP_ALL_POSE_UPDATESerializer('getFormat'));
gcs_machine.ipcAPI('define','Global_Planner_MAGIC_MAP',  MagicGP_MAGIC_MAPSerializer('getFormat'));

tUpdate = 0.1;
%ids = [1 3];
%ids = [3];
ids = [1 2 3];

for id = ids,
  Robots(id).traj.handle = -1;
end

gcsEntryIPC(ids)
mapDisplay('entry');
% GCS_GUI;

while 1,
    count = count +1;
  pause(tUpdate);
  gcsUpdateIPC;
  mapDisplay('update');
  if (mod(count, 50)==0)
      sendMapToExploration;
  end
% UpdateGoals;
end

end

