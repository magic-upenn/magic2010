%SetMagicPaths

dev = '/dev/ttyACM0';
serialDeviceAPI('connect','/dev/ttyACM1',9600);
serialDeviceAPI('setTermSequenceEndLine');

gpsMsgName = 'Robot5/GPS';

ipcAPIConnect('localhost');
ipcAPIDefine(gpsMsgName,MagicGpsASCIISerializer('getFormat'));

while(1)
  chars = serialDeviceAPI('read',1000,1500000);
  if ~isempty(chars)
      gpsStr = char(chars);
      
      packet.t    = GetUnixTime();
      packet.id   = 0;
      packet.size = length(gpsStr);
      packet.data = uint8(gpsStr);
      
      rawData = MagicGpsASCIISerializer('serialize',packet);
      ipcAPIPublishVC(gpsMsgName,rawData);
      fprintf('.');
      
      %packet2 = MagicGpsASCIISerializer('deserialize',rawData);
      %data2 = char(packet2.data)
  end
end
