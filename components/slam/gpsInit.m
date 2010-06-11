function gpsInit
global GPS

id = GetRobotId();

if isempty(GPS) || ~isfield(GPS,'initialized') ||(GPS.initialized ~= 1)
  GPS.msgName = [GetRobotName '/GPS'];
  
  ipcInit;
  ipcAPIDefine(GPS.msgName,MagicGpsASCIISerializer('getFormat'));
  
  GPS.initialized = 1;
  disp('Gps initialized');
end
  
