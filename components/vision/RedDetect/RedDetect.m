function RedDetect
%global VISION_IPC host
	global POSE LIDAR PARAMS; 
	POSE.data = [];
	SetMagicPaths;
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
	ipcInit;
	ipcReceiveSetFcn(GetMsgName('CamParams'),@CamParamsMsgHandler);
	ipcReceiveSetFcn(GetMsgName('Pose'),     @PoseMsgHander);
	ipcReceiveSetFcn(GetMsgName('Lidar0'),   @VisionLidarHHandler);
	ipcReceiveSetFcn(GetMsgName('Lidar1'),   @VisionLidarVHandler);
	ipcReceiveSetFcn(GetMsgName('Servo1'),   @VisionServoHandler);
	LIDAR.scanH = [];
	LIDAR.scanV = [];
	LIDAR.servo = 0;
	PARAMS.omni = []; 
	PARAMS.front = []; 
	masterIp = '192.168.10.221';
	masterPort = 12345;
	UdpSendAPI('connect',masterIp,masterPort);

	%%%%%%%%%%%%%%%%%%
	ftime = .25; 
	otime = .25; 
	ftic = tic;
	otic = tic; 
	while(1)
		ipcReceiveMessages;
		if toc(ftic) >= ftime
			'Get front_packet'
			packet = front_packet(); 
			UdpSendAPI('send',packet);
			ftic = tic; 
		end
		if toc(otic) >= otime
			'Get omni_packet'
			packet = omni_packet(); 
			UdpSendAPI('send',packet);
			otic = tic; 
		end
		tic; 
	end	
	
function imPacket = omni_packet()
	global POSE LIDAR PARAMS; 
	[omni, omni_cands, omni_stats] = red_detect_cams('omni');
	if isempty(PARAMS.omni)
		PARAMS.omni = get_ctrl_values(0); 
	end
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = GetRobotId(); 
	imPacket.type = 'OmniVision';  
	imPacket.t  = GetUnixTime();
	imPacket.omni = cjpeg(omni,quality);
	imPacket.front_angle = LIDAR.servo;
	for im = 1:3
		imPacket.omni_cands{im}  = cjpeg(omni_cands{im},quality);
	end 
	imPacket.omni_stats = omni_stats;
	imPacket.pose = POSE.data; 
	imPacket.params = PARAMS.omni; 
	imPacket = zlibCompress(serialize(imPacket));

function imPacket = front_packet()
	global POSE LIDAR PARAMS;  
	[front, front_cands, front_stats] = red_detect_cams('front');
	if isempty(PARAMS.front)
		PARAMS.front = get_ctrl_values(1); 
	end
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = GetRobotId(); 
	imPacket.type = 'FrontVision';  
	imPacket.t  = GetUnixTime();
	imPacket.front = cjpeg(front,quality);
	imPacket.front_angle = LIDAR.servo;
	imPacket.scanH = LIDAR.scanH;
	imPacket.scanV = LIDAR.scanV;
	for im = 1:3
		imPacket.front_cands{im} = cjpeg(front_cands{im},quality);
	end 
	imPacket.front_stats = front_stats;
	imPacket.pose = POSE.data; 
	imPacket.params = PARAMS.front; 
	imPacket = zlibCompress(serialize(imPacket));


function PoseMsgHander(data,name)
	global POSE
	POSE.data = [];
	if isempty(data)
	    return;
	end
	POSE.data = MagicPoseSerializer('deserialize',data);

function CamParamsMsgHandler(data,name)
	global PARAMS
  'Changing params'
  if isempty(data)
    		return;
	end
	params = deserialize(data);
  if params.cam == 0
		PARAMS.omni = params;
    set_ctrl_values(0,params); 
	end 
	if params.cam == 1
		PARAMS.front = params;
    set_ctrl_values(1,params); 
	end 

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

