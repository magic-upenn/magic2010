function sendEstopState(state,host)
persistent initialized msgName

if (nargin < 2)
  host = 'localhost';
end

if isempty(initialized)
  SetMagicPaths;
  ipcAPIConnect(host);
  msgName = GetMsgName('EstopState');
  ipcAPIDefine(msgName,MagicEstopStateSerializer('getFormat'));
end


while(1)
  s.state = state;
  s.t     = GetUnixTime();
  
  raw = MagicEstopStateSerializer('serialize',s);
  ipcAPIPublish(msgName,raw);
  
  fprintf(1,'published estop state = %d\n',s.state);
  
  pause(1);
end