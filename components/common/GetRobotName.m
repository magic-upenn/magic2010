function name = GetRobotName()
robotIdStr = getenv('ROBOT_ID');
if isempty(robotIdStr)
  error('robot id is not defined in an environment variable');
end

name = ['Robot' robotIdStr];
