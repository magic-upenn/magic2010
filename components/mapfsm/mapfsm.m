function mapfsm(tUpdate)

global MP

more off;
if nargin < 1,
  tUpdate = 0.1;
end

% Construct state machine:
MP.sm = statemch('sInitial');
MP.sm = addState(MP.sm, 'sWait');
MP.sm = addState(MP.sm, 'sSpinLeft');
%MP.sm = addState(MP.sm, 'sWaypoint');
%MP.sm = addState(MP.sm, 'sBackup');
MP.sm = addState(MP.sm, 'sFreeze');

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sWait' ...
                             );
MP.sm = setTransition(MP.sm, 'sWait', ...
                             'spinLeft', 'sSpinLeft' ...
                             );
MP.sm = setTransition(MP.sm, 'sSpinLeft', ...
		      'done', 'sWait', ...
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
