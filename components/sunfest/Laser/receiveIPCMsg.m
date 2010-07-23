clear all;
SetMagicPaths;
ipcAPI('connect','localhost');
ipcAPI('subscribe','Robot1/VelocityCmd');

while(1)
	messages = ipcAPI('receive');
	for i=1:length(messages)
		vel = MagicVelocityCmdSerializer('deserialize',messages.data)
	end
end