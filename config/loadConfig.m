function ret = loadConfig(id)

if nargin < 1
  id = GetRobotId();
end

fname = sprintf('loadConfig%d',id);

eval(fname);