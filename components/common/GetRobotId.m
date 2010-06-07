function id = GetRobotId()

robotIdStr = getenv('ROBOT_ID');
if isempty(robotIdStr)
  error('robot id is not defined in an environment variable');
end

id = str2double(robotIdStr);

if isnan(id)
    error('id is NAN');
end
