function mapfsm(tUpdate)

global MP MAP

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
MP.sm = addState(MP.sm, 'sWait');
MP.sm = addState(MP.sm, 'sSpinLeft');
MP.sm = addState(MP.sm, 'sSpinRight');
MP.sm = addState(MP.sm, 'sBackup');
MP.sm = addState(MP.sm, 'sPath');
%MP.sm = addState(MP.sm, 'sLook');
%MP.sm = addState(MP.sm, 'sTrackHuman');
MP.sm = addState(MP.sm, 'sFreeze');

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sWait', ...
                             'waypoint', 'sWaypoint', ...
                             'backup', 'sBackup', ...
                             'spinLeft', 'sSpinLeft', ...
                             'spinRight', 'sSpinRight' ...
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
  % TODO

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
