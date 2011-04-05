function ret=renice(val,pid)

if (nargin < 2)
  pid = getpid();
end

cmd = sprintf('renice %d %d',val,pid);
[ret retStr] = unix(cmd);