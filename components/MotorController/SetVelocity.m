function ret = SetVelocity(v,w)

persistent ipcMsgName

if isempty(ipcMsgName)
  robotId = getenv('ROBOT_ID');
  if isempty(robotId)
    error('robot id is not set');
  end
  
  ipcMsgName = ['Robot' robotId '/VelocityCmd'];
  
  ipcAPIConnect();
  ipcAPIDefine(ipcMsgName,MagicVelocityCmdSerializer('getFormat'));
end

vcmd.t = 0; %GetUnixTime();
vcmd.v = v;
vcmd.w = w;

content = MagicVelocityCmdSerializer('serialize',vcmd);
ipcAPIPublishVC(ipcMsgName,content);

ret =1;
