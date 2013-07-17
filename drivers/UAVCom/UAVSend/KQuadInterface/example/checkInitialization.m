clear all
addpath '../QC-12.12.12/api'

SerialDeviceAPI('connect','/dev/ttyUSB0',115200)

while(1)
    packet=SerialDeviceAPI('read',10000);
    if ~isempty(packet)
        d=char(packet)
        disp(d)
    end
end