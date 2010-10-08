function RedDetect
%global VISION_IPC host
	SetMagicPaths;
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
%	global POSE targetY
%	POSE.data = [];

	ipcInit;
	imageMsgName = GetMsgName('Image');
%	staticOoiMsgName = GetMsgName('StaticOOI');
	ipcAPIDefine(imageMsgName);
%	ipcAPIDefine(staticOoiMsgName);

	ipcReceiveSetFcn(GetMsgName('Pose'), @PoseMsgHander);
%	ipcReceiveSetFcn(GetMsgName('CamParam'), @CamParamMsgHander);

	%%%%%%%%%%%%%%%%%%
	counter = 0; 
	while(1)
		counter = counter + 1;
		%Get Image Here
		%Compute red here

	    % Calculate details of each red box candidate

	    %%%% send images and OOI to vision GUI console through IPC %%%%%
		ipcReceiveMessages;
		[omni_sm, front_sm, omni_cands, front_cands, omni_stats, front_stats] = red_detect_cams();

		%%%%% send compressed jpg image through IPC %%%%%
		imPacket.id = str2double(getenv('ROBOT_ID'));
		imPacket.t  = GetUnixTime();
		imPacket.omni = cjpeg(omni_sm);
		imPacket.front = cjpeg(front_sm);
		imPacket.front_angle = 0;
		for im = 1:3
			imPacket.omni_cands{im}  = cjpeg(omni_cands{im});
			imPacket.front_cands{im} = cjpeg(front_cands{im});
		end 
		imPacket.omni_stats = omni_stats;
		imPacket.front_stats = front_stats;
		imPacket.pose = POSE.data; 
		ipcAPIPublish(imageMsgName,serialize(imPacket));
	end

function PoseMsgHander(data,name)
	global POSE
	POSE.data = [];
	if isempty(data)
	    return;
	end
	POSE.data = MagicPoseSerializer('deserialize',data);

function CamParamMsgHander(data,name)
global targetY
if isempty(data)
    return;
end

targetY = deserialize(data);
