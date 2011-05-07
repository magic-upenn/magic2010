function RascalmapfsmRecvServoFcn(data,name)
global SERVO_ANGLE

if ~isempty(data)
  servo = MagicServoStateSerializer('deserialize',data);
  SERVO_ANGLE = servo.position + 0.12;
end

