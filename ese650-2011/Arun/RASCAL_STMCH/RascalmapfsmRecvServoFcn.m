function RascalmapfsmRecvServoFcn(data,name)
global SERVO_ANGLE

if ~isempty(data)
  servo = MagicServoStateSerializer('deserialize',data);
  SERVO_ANGLE = servo.position;
end

