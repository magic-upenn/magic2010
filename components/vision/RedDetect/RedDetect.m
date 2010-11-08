function RedDetect
%global VISION_IPC host
	global GLOBALS; 
	GLOBALS.tweekH = 0; 
	GLOBALS.tweekV = 0; %.15;
     	GLOBALS.startAngle = -2.356194496154785;
      	GLOBALS.stopAngle = 2.356194496154785;
      	GLOBALS.angleStep = 0.004363323096186;
	GLOBALS.scan_angles = GLOBALS.startAngle:GLOBALS.angleStep:GLOBALS.stopAngle; 
	'Adding controls'
	system('sh $MAGIC_DIR/components/vision/RedDetect/add_ctrls.sh&')
	pause(1)
	'Added controls'
	global POSE LIDAR PARAMS FTIME OTIME FTIME2 OTIME2; 
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
	ipcReceiveSetFcn(GetMsgName('Lazer_Msg'),   @LazerMsgHandler);
  ipcReceiveSetFcn(GetMsgName('EstopState'),   @EstopMsgHandler);
	
  LIDAR.scanH = [];
	LIDAR.scanV = [];
	LIDAR.servo = 0;
	PARAMS.omni = []; 
	PARAMS.front = []; 
	masterIp = '192.168.10.221';
	masterPort = 12345;
	UdpSendAPI('connect',masterIp,masterPort);

	%%%%%%%%%%%%%%%%%%
	FTIME = .5; 
	OTIME = .5; 
    FTIME2 = FTIME;
    OTIME2 = OTIME;
	ftic = tic;
	otic = tic; 
	while(1)
		pause(.1)
		ipcReceiveMessages;
		if toc(ftic) >= FTIME
			packet = front_packet(); 
			UdpSendAPI('send',packet); 
      stat = whos('packet'); 
			sprintf('Sent front_packet, size %d', stat.bytes)
      ftic = tic; 
		end
		if toc(otic) >= OTIME
			packet = omni_packet(); 
			UdpSendAPI('send',packet);
			sprintf('Sent omni_packet, size %d', stat.bytes)
			otic = tic; 
		end
		tic; 
	end	
	
function imPacket = omni_packet()
	global POSE LIDAR PARAMS OTIME FTIME GLOBALS; 
	[omni, omni_stats] = red_detect_cams('omni');
	if isempty(PARAMS.omni)
		PARAMS.omni = get_ctrl_values(0); 
	end
	PARAMS.omni.otime = OTIME; 
	PARAMS.omni.ftime = FTIME; 
	quality = 75;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = GetRobotId(); 
	imPacket.type = 'OmniVision';  
	imPacket.t  = GetUnixTime();
	imPacket.omni = cjpeg(omni,quality);
	imPacket.front_angle = LIDAR.servo;
	imPacket.omni_stats = omni_stats;
	imPacket.pose = POSE.data; 
	imPacket.params = PARAMS.omni; 
	imPacket = zlibCompress(serialize(imPacket));

function imPacket = front_packet()
	global POSE LIDAR PARAMS OTIME FTIME;  
	[front, front_stats] = red_detect_cams('front');
	if isempty(PARAMS.front)
		PARAMS.front = get_ctrl_values(1); 
	end
	PARAMS.front.otime = OTIME; 
	PARAMS.front.ftime = FTIME; 
	quality = 75;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = GetRobotId(); 
	imPacket.type = 'FrontVision';  
	imPacket.t  = GetUnixTime();
	imPacket.front = cjpeg(front,quality);
	imPacket.front_angle = LIDAR.servo;
	if isempty(LIDAR.scanH)
		LIDAR.scanH.ranges = zeros(1081,1); 
	end
	if isempty(LIDAR.scanV)
		LIDAR.scanV.ranges = zeros(1081,1); 
	end
	scanH =  fliplr(LIDAR.scanH.ranges);
	scanV =  fliplr(LIDAR.scanV.ranges);
	[rangeH,rangeV] = get_range_in_view(scanH,scanV,front,imPacket.front_angle,60,60); 
	imPacket.rangeH = uint8(rangeH*10); 
	imPacket.rangeV = uint8(rangeV*10); 
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
	global PARAMS OTIME FTIME FTIME2 OTIME2
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
  if params.cam == 2
    OTIME = params.otime; 
    FTIME = params.ftime;
    OTIME2 = OTIME;
    FTIME2 = FTIME;
    sprintf('Timings are now %f %f',OTIME,FTIME)
  end

function LazerMsgHandler(data,name)
	msg = deserialize(data); 
	switch (msg.status)
	case 'on'
		laserOn; 
	case 'off'
		laserOff; 
	otherwise	
		return
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

function EstopMsgHandler(data,name)
global FTIME OTIME FTIME2 OTIME2
if ~isempty(data)
  state = MagicEstopStateSerializer('deserialize',data);
  if ~isfield(state,'state'), return, end
  
  if (state.state ~= 0)
    FTIME = inf;
    OTIME = inf;
  
  else
    FTIME = FTIME2;
    OTIME = OTIME2;
  end
end

