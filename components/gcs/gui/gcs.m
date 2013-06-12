function gcs(log_type,log_file)
more off;

%load parameters
gcsParams;

% load up from a log file (possibly)
global INIT_LOG INIT_REGIONS RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS

if nargin > 0
  switch log_type
  case 'full'
    disp('Starting GCS from FULL LOG');
    INIT_LOG = true;
    INIT_REGIONS = false;
    load(log_file);
  case 'regions'
    disp('Starting GCS with REGION LOG');
    INIT_LOG = false;
    INIT_REGIONS = true;
    load(log_file);
  otherwise
    disp('WARNING: Unrecognized log type! Starting GCS from scratch');
    INIT_LOG = false;
    INIT_REGIONS = false;
  end
else
  disp('Starting GCS from scratch');
  INIT_LOG = false;
  INIT_REGIONS = false;
end

%%%  gcs stuff
global gcs_machine HAVE_ROBOTS
last_explore_update = gettime;

gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
gcs_machine.ipcAPI('define','Global_Planner_DATA',  MagicGP_DATASerializer('getFormat'));
ipcReceiveSetFcn('Global_Planner_TRAJ',@GPTRAJHandler,gcs_machine.ipcAPI,2);
ipcReceiveSetFcn('OOI_Msg',@gcsRecvOOIFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('OOI_Done_Msg',@gcsRecvOOIDoneFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('UAV_Feed',@gcsRecvUAVFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('Global_Map',@gcsRecvGlobalMapFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('RPose',@gcsRecvRPoseFcn,gcs_machine.ipcAPI,30);
ipcReceiveSetFcn('IncH',@gcsRecvIncHFcn,gcs_machine.ipcAPI,30);
ipcReceiveSetFcn('IncV',@gcsRecvIncVFcn,gcs_machine.ipcAPI,30);

tUpdate = 0.1;

initExploreTemplates();
gcsEntryIPC()
mapDisplay('entry');


screenshotCntr = 1;
lastScreenshotTime = gettime;


drawnow;


global GDISPLAY

set(GDISPLAY.hFigure,'Renderer','zbuffer');
drawnow;

%winsize = get(GDISPLAY.hFigure,'Position')
%winsize(1:2) = [0 0];
%numframes = 1000;
%A=moviein(numframes,GDISPLAY.hFigure,winsize);

while 1,
  %pause(tUpdate);
  fprintf('before gcs UpdateIPC\n')
  gcsUpdateIPC;
  fprintf('before mapDisplay\n')
  mapDisplay('update');
  if ((gettime - last_explore_update > 5.0) && HAVE_ROBOTS)
    sendMapToExploration;
    last_explore_update = gettime;
  end

%{
  if (gettime - lastScreenshotTime > 0.1)
    A(:,screenshotCntr) = getframe(GDISPLAY.hFigure,winsize);
    screenshotCntr=screenshotCntr+1;
    lastScreenshotTime = gettime;
    fprintf('saved frame\n');
  end
  %}
end

end

