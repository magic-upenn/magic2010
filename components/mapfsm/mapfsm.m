function mapfsm(tUpdate)

global MP

more off;
if nargin < 1,
  tUpdate = 0.1;
end

% Construct state machine:
MP.sm = statemch('sInitial');
%MP.sm = addState(MP.sm, 'sWait');
%MP.sm = addState(MP.sm, 'sSpin');
%MP.sm = addState(MP.sm, 'sWaypoint');
%MP.sm = addState(MP.sm, 'sBackup');
MP.sm = addState(MP.sm, 'sFreeze');

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sFreeze' ...
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

% Initialize IPC
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'), @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('StateEvent'), @mapfsmRecvStateEventFcn);

MP.sm = entry(MP.sm);

%==========
function mapfsmUpdate

global MP

% Check IPC messages
ipcReceiveMessages;

MP.sm = update(MP.sm);


%==========
function mapfsmExit

global MP

MP.sm = exit(MP.sm);
