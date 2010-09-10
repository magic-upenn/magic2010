function mapfsm(tUpdate)

global MP MAP SPEED

SPEED.minTurn = 0.6;

more off;
if nargin < 1,
  tUpdate = 0.1;
end

% Construct map:
MAP = map2d(600,600,.10,'vlidar','hlidar','cost');

% Miscellaneous fields
MP.nupdate = 0;
MP.debugPlot = 0;

% Construct state machine:
MP.sm = statemch('sInitial');
% Central waiting state
MP.sm = addState(MP.sm, 'sWait');
% Spins to look 360 deg around
MP.sm = addState(MP.sm, 'sSpinLeft');
MP.sm = addState(MP.sm, 'sSpinRight');
% Go back
MP.sm = addState(MP.sm, 'sBackup');
% Navigate path, using obstacle detection
MP.sm = addState(MP.sm, 'sPath');
% Blindly follow path
MP.sm = addState(MP.sm, 'sFollow');
% Look at static OOI
MP.sm = addState(MP.sm, 'sLook');
MP.sm = addState(MP.sm, 'sLookPath');
% Track human
MP.sm = addState(MP.sm, 'sTrackHuman');
MP.sm = addState(MP.sm, 'sFreeze');
%a state that waits for a path from the lattice planner before passing it to the follower
MP.sm = addState(MP.sm, 'sGoToPoint');
%a state that gets exploration paths and sends them to a path follower
MP.sm = addState(MP.sm, 'sExplore');
%a state that follows an exploration path and returns to sExplore when done for a new path
MP.sm = addState(MP.sm, 'sExplorePath');

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sWait', ...
                             'path', 'sPath', ...
                             'follow', 'sFollow', ...
                             'backup', 'sBackup', ...
                             'spinLeft', 'sSpinLeft', ...
                             'spinRight', 'sSpinRight', ...
                             'track', 'sTrackHuman', ...
                             'explore', 'sExplore', ...
                             'goToPoint', 'sGoToPoint' ...
                             );
MP.sm = setTransition(MP.sm, 'sSpinLeft', ...
                             'done', 'sWait', ...
		                         'stop', 'sWait', ...
                             'timeout', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sSpinRight', ...
                             'done', 'sWait', ...
		                         'stop', 'sWait', ...
                             'timeout', 'sWait' ...		         
                             );
MP.sm = setTransition(MP.sm, 'sBackup', ...
                             'done', 'sWait', ...
		                         'stop', 'sWait', ...
                             'timeout', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sPath', ...
                             'done', 'sWait', ...
                             'stop', 'sWait', ...
                             'obstacle', 'sWait', ...
                             'follow', 'sFollow', ...
                             'timeout', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sFollow', ...
                             'done', 'sWait', ...
                             'stop', 'sWait', ...
                             'timeout', 'sPath' ...
                             );
MP.sm = setTransition(MP.sm, 'sGoToPoint', ...
                             'stop', 'sWait', ...
                             'done', 'sWait' ...
                             );
                             %{
                             'gotGoToPointPath', 'sPath', ...
                             'stop', 'sWait', ...
                             'timeout', 'sWait' ...
                             );
                             %}

MP.sm = setTransition(MP.sm, 'sExplore', ...
                             'stop', 'sWait' ...
                             );
                             %{
                             'gotExplorePath', 'sExplorePath', ...
                             'timeout', 'sWait' ...
                             );
                             %}
MP.sm = setTransition(MP.sm, 'sExplorePath', ...
                             'done', 'sExplore', ...
                             'stop', 'sWait', ...
                             'obstacle', 'sExplore', ...
                             'timeout', 'sExplore' ...
                             );

MP.sm = setTransition(MP.sm, 'sLook', ...
                             'gotPath', 'sLookPath', ...
                             'stop', 'sWait', ...
                             'timeout', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sLookPath', ...
                             'done', 'sWait', ...
                             'stop', 'sWait', ...
                             'obstacle', 'sLook', ...
                             'timeout', 'sWait' ...
                             );
                             
MP.sm = setTransition(MP.sm, 'sTrackHuman', ...
                             'stop', 'sWait', ...
                             'timeout', 'sWait' ...
                             );

mapfsmEntry;

loop = 1;
while (loop),
  pause(tUpdate);
  mapfsmUpdate;
end

mapfsmExit;

%==========
function mapfsmEntry

global MP

MP.sm = entry(MP.sm);

% Initialize IPC
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'), @mapfsmRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('StateEvent'), @mapfsmRecvStateEventFcn);
ipcReceiveSetFcn(GetMsgName('IncMapUpdateH'), @mapfsmRecvIncMapUpdateHFcn);
ipcReceiveSetFcn(GetMsgName('IncMapUpdateV'), @mapfsmRecvIncMapUpdateVFcn);
ipcReceiveSetFcn(GetMsgName('Path'), @mapfsmRecvPathFcn);
ipcReceiveSetFcn(GetMsgName('Goal_Point'), @mapfsmRecvGoalPointFcn);
ipcReceiveSetFcn(GetMsgName('Planner_GoToPoint'), @mapfsmRecvPlannerPathFcn);
ipcReceiveSetFcn(GetMsgName('Planner_Explore'), @mapfsmRecvExplorePathFcn);

% Tracks from slam:
ipcReceiveSetFcn(GetMsgName('VelTracks'), @mapfsmRecvVelTracksFcn);
% OOI initial position from gcs:
ipcReceiveSetFcn(GetMsgName('OoiDynamic'), @mapfsmRecvOoiDynamicFcn);

ipcAPIDefine(GetMsgName('Cost_Map_Full'),MagicGP_MAGIC_MAPSerializer('getFormat'));
ipcAPIDefine(GetMsgName('Planner_State'),MagicGP_SET_STATESerializer('getFormat'));


%==========
function mapfsmUpdate

global MP
global MPOSE MAP

MP.nupdate = MP.nupdate + 1;

% Check IPC messages
ipcReceiveMessages;

MP.sm = update(MP.sm);

if ~isempty(MPOSE) && rem(MP.nupdate, 10) == 0,
  % See if map needs to be shifted:
  [mx0, my0] = origin(MAP);
  if (abs(MPOSE.x - mx0) > 15.0) || ...
    (abs(MPOSE.y - my0) > 15.0),
    MAP = shift(MAP, MPOSE.x, MPOSE.y);
  end

  % Ship out map here for local planner:
  %{
  [planMap.size_x, planMap.size_y] = size(MAP);
  planMap.resolution = resolution(MAP);
  xmap = x(MAP);
  planMap.UTM_x = xmap(1);
  ymap = y(MAP);
  planMap.UTM_y = ymap(1);
  planMap.map = int16(getdata(MAP, 'cost'));
  ipcAPIPublishVC(GetMsgName('Cost_Map_Full'), ...
                  MagicGP_MAGIC_MAPSerializer('serialize', planMap));
  %}
  

  if (MP.debugPlot),
    imagesc(dx(MAP), dy(MAP), getdata(MAP, 'cost'), [-100 100]);
    hold on;
      plot(MPOSE.x, MPOSE.y, 'r*')
    colormap jet;
    drawnow
  end
  

end

%==========
function mapfsmExit

global MP

MP.sm = exit(MP.sm);
