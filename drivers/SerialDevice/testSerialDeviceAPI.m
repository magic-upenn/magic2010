serialDeviceAPI('connect','/dev/ttyUSB1',9600);
serialDeviceAPI('write',sprintf('My name is Matlab\n'));
serialDeviceAPI('read',5,5000000)