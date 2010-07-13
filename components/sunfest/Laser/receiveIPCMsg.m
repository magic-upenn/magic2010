clear all;
SetMagicPaths;
ipcAPI('connect','localhost');
ipcAPI('subscribe','Robot1/PoseTruth');

while(1)
	messages = ipcAPI('receive');
	for i=1:length(messages)
		robotPose = MagicPoseSerializer('deserialize',messages(i).data)
	end
end