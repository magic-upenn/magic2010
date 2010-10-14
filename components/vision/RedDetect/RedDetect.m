function RedDetect
%global VISION_IPC host
	global POSE LIDAR; 
	POSE.data = [];
	SetMagicPaths;
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
%	global POSE targetY

	ipcInit;
	imageMsgName = GetMsgName('Image');
	ipcAPIDefine(imageMsgName);
	ipcReceiveSetFcn(GetMsgName('Pose'), @PoseMsgHander);
	ipcReceiveSetFcn(GetMsgName('Lidar0'), @VisionLidarHHandler);
	ipcReceiveSetFcn(GetMsgName('Lidar1'), @VisionLidarVHandler);
	ipcReceiveSetFcn(GetMsgName('Servo1'), @VisionServoHandler);
	LIDAR.scanH = [];
	LIDAR.scanV = [];
	LIDAR.servo = 0;
	masterIp = '192.168.10.221';
	masterPort = 12345;
	UdpSendAPI('connect',masterIp,masterPort);

	%%%%%%%%%%%%%%%%%%
	counter = 0; 
	while(1)
		counter = counter + 1;
		%Get Image Here
		%Compute red here
		quality = 80; 
	    % Calculate details of each red box candidate

	    %%%% send images and OOI to vision GUI console through IPC %%%%%
		ipcReceiveMessages;
		[omni_sm, front_sm, omni_cands, front_cands, omni_stats, front_stats] = red_detect_cams();

		%%%%% send compressed jpg image through IPC %%%%%
		imPacket.id = GetRobotId(); 
		imPacket.type = 'Vision';  
		imPacket.t  = GetUnixTime();
		imPacket.omni = cjpeg(omni_sm,quality);
		imPacket.front = cjpeg(front_sm,quality);
		imPacket.front_angle = LIDAR.servo;
		imPacket.scanH = LIDAR.scanH;
		imPacket.scanV = LIDAR.scanV;
		for im = 1:3
			imPacket.omni_cands{im}  = cjpeg(omni_cands{im},quality);
			imPacket.front_cands{im} = cjpeg(front_cands{im},quality);
		end 
		imPacket.omni_stats = omni_stats;
		imPacket.front_stats = front_stats;
		imPacket.pose = POSE.data; 
		raw = serialize(imPacket);
		zraw = zlibCompress(raw);
		UdpSendAPI('send',zraw);
		%Send message to vision gsc
		%ipcAPIPublish(imageMsgName,serialize(imPacket));
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

function VisionLidarHHandler(data,name)
global LIDAR

if ~isempty(data)
  LIDAR.scanH = MagicLidarScanSerializer('deserialize',data);
end

function VisionLidarVHandler(data,name)
global LIDAR

if ~isempty(data)
  LIDAR.scanV = MagicLidarScanSerializer('deserialize',data);
end

function VisionServoHandler(data,name)
global LIDAR

if ~isempty(data)
  servo = MagicServoStateSerializer('deserialize',data);
  LIDAR.servo = servo.position;
end

