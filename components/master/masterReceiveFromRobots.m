function nmsgs = masterReceiveFromRobots(dt)
global ROBOTS HAVE_ROBOTS
global IPC

if nargin <1
    dt=10;
end

if ~HAVE_ROBOTS
  return;
end

nRobots = length(ROBOTS);
if nRobots < 1
  error('not connected to robots');
end

nmsgs = 0;

for ii=1:nRobots
  if ROBOTS(ii).connected
    %receive messages from a robot
    %options are : 
    % listen: wait up to specified time, but return right away if a message
    %    is received
    % listenClear: wait until no messages come within the specified period
    % listenWait:  like usleep, but will receive messages for specified time            
    msgs = ROBOTS(ii).ipcAPI('listen',dt);
    nmsg = length(msgs);
    
    %process messages
    for mi=1:nmsg
      name = msgs(mi).name;
      name(name=='/')='_';
      if isfield(IPC.handler,name),
        IPC.handler.(name)(msgs(mi).data,msgs(mi).name);
      else
        warning('no handler for message name %s',msgs(mi).name);
      end
    end
  end
end
