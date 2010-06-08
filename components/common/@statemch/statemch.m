function h = statemch(varargin)
% statemch(state_list)
% Create a State Machine object.

if nargin < 1,
  error('Statemch construction needs at least one input argument');
end

if isa(varargin{1}, 'statemch'),
  % If given a statemch object, give it back.
  h = varargin{1};
  return;
else
  if isa(varargin{1}, 'cell'),
    % Cell array input
    varargin = varargin{1};
  end

  h.nStates = length(varargin);
  h.states = varargin;

  for i = 1:length(h.nStates),
    h.statesHash.(h.states{i}) = i;
  end
end

h.status = 'Stopped';
h.transitions = cell(h.nStates,1);
h.currentState = 1;
h.nextState = [];
h.previousState = 1;
h.entryTime = [];
h.history = cell(100,1);
h.events = {};

% Make the cast.
h = class(h,'statemch');
