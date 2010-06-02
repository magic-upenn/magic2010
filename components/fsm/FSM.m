function ret = FSM(varargin)
% FSM(states)

% Create state functions as follows:
%{
function ret = State(varargin)
  S.entry = @entry;
  S.exit = @exit;
  S.update = @update;
  ret = S;

function entry
  S.tic = tic;
end
function exit
end
function ret = update
  if toc(S.tic) > 1.0
    ret = 'timeout';
    return;
  end
end
end % State function
%}
% Then create and use the state machine as follows:
% sm = FSM('State');
% sm.setTransition('State', 'timeout', 'State');
% sm.entry();
% for i = 1:100, sm.update(); end
% sm.exit();

if nargin < 1,
  error('Statemch construction needs state arguments');
end

SM.entry = @entry;
SM.exit = @exit;
SM.update = @update;
SM.setState = @setState;
SM.setTransition = @setTransition;
SM.set = @set;
SM.get = @get;
ret = SM;

SM.nStates = nargin;
for i = 1:SM.nStates,
  str = varargin{i};
  SM.statesName{i} = str;
  SM.statesHash.(str) = i;
  SM.statesFunc{i} = feval(str);
end

SM.transitions = cell(1, SM.nStates);
SM.currentState = 1;
SM.nextState = [];
SM.nextArg = {};
SM.previousState = 1;

function entry
  SM.statesFunc{SM.currentState}.entry();
end

function update
  % If no next state, update current state function:
  if isempty(SM.nextState),
    ret = SM.statesFunc{SM.currentState}.update();
    if ~isempty(ret),
      if isfield(SM.transitions{SM.currentState}, ret),
        % Set next state using transitions field
        SM.nextState = SM.transitions{SM.currentState}.(ret).state;
        SM.nextArg = SM.transitions{SM.currentState}.(ret).arg;
      else
%        disp(sprintf('Warning: Unknown return code: %s from state %s', ...
%                ret, SM.statesName{SM.currentState}));
        disp(sprintf('Warning: Unknown return code: %s from state %d', ...
                ret, SM.currentState));
keyboard
      end
    end
  end

  if ~isempty(SM.nextState),
    SM.statesFunc{SM.currentState}.exit();
    SM.currentState = SM.nextState;
    SM.statesFunc{SM.currentState}.entry(SM.nextArg{:});
    SM.nextState = [];
    SM.nextArg = {};
  end
end

function exit
  SM.statesFunc{SM.currentState}.exit();
end

function setState(state, varargin)
  SM.nextState = SM.statesHash.(state);
  SM.nextArg = varargin;
end

function setTransition(state, condition, next, varargin)
  index = SM.statesHash.(state);
  if ~isempty(next),
    SM.transitions{index}.(condition).state = SM.statesHash.(next);
    SM.transitions{index}.(condition).arg = varargin;
  else
    SM.transitions{index}.(condition).state = [];
    SM.transitions{index}.(condition).arg = {};
  end    
end

function set(field, val)
  SM.(field) = val;
end

function ret = get(field)
  ret = SM.(field);
end

end % FSM function
