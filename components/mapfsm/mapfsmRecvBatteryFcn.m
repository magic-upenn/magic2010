function mapfsmRecvLookMsgFcn(data, name)
global BATTERY

if ~isempty(data)
  %disp('got battery msg');
  msg = MagicBatteryStatusSerializer('deserialize',data);

  BATTERY = msg.voltage;
end
