function name = GetMsgName(msgType,id)

if nargin > 1
  robotName = ['Robot' sprintf('%d',id)];
else
  robotName = GetRobotName;
end
name = [robotName '/' msgType];