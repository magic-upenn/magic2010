pid=getpid();

cmd = sprintf('cpulimit --pid %d --limit 50',pid);

unix(cmd);

while(1)


end