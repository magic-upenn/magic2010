function status = spreadReceiveSetFcn(group, func)

global SPREAD

if nargin < 2 || ~isa(func,'function_handle'),
  error('Need to input a function handle');
end

SPREAD.handler.(group) = func;
status = spreadAPIJoin(group);
