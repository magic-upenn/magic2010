function visionGuiSim(ids)
	if nargin ~= 1
		'Need ids'
		return
	end
	SetMagicPaths
	visionGuiInit;
	global SIMAGES GLOBALS ROBOTS PARAMS LIDAR POSE; 
	PARAMS.omni = []; 
	PARAMS.front = []; 
	LIDAR.servo = 0;
	LIDAR.scanH.ranges = rand(1,1081);
	LIDAR.scanV.ranges = rand(1,1081);
	POSE.data.x = 10; 
	POSE.data.y = 10; 
	POSE.data.yaw = 0; 
	 
	gtime = .5; 
	gtic = tic;
	for i = 1:9
		ROBOTS(i).connected = 0;
	end
	for i = ids
		ROBOTS(i).connected = 1;
	end
	cids = ids; 
	guit = tic; 	
	utime = .5;
	last_packets = {};  
	while(1)
		cids = circshift(cids,[0,1]); 
		%last_packets{end+1} = front_packet_dummy(cids(1)); 
		%last_packets{end+1} = omni_packet_dummy(cids(1));
		last_packets{end+1} = get_packet_saved(cids(1));
	 
		if toc(guit) > utime
			'Updating gui'
			if numel(last_packets) > 0 & numel(last_packets) < 35
				GLOBALS.updateWithPackets(last_packets); 
			end
			last_packets = {};  
			guit = tic; 
		end 
	end

function imPacket = get_packet_saved(id)
	global last_packets
	imPacket = last_packets{round(rand()*110) + 1};
	imPacket.id = id; 
	pause(.1)

function imPacket = omni_packet_dummy(id)
	global POSE LIDAR PARAMS;
	global SIMAGES
	IMGS = SIMAGES{floor(rand()*9)+1}; 
	omni = IMGS(id).omni; 
	omni_stats = IMGS(id).omni_stats; 
	omni_cands = IMGS(id).omni_cands; 
	if isempty(PARAMS.omni)
		PARAMS.omni = get_ctrl_values(-1); 
	end
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = id; 
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
	pause(.1)	

function imPacket = front_packet_dummy(id)
	global POSE LIDAR PARAMS;  
	global SIMAGES
	IMGS = SIMAGES{floor(rand()*9)+1}; 
	front = IMGS(id).front; 
	front_stats = IMGS(id).front_stats; 
	front_cands = IMGS(id).front_cands; 
	if isempty(PARAMS.front)
		PARAMS.front = get_ctrl_values(-1); 
	end
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = id; 
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
	pause(.1)	

function imPacket = omni_packet()
	global POSE LIDAR PARAMS; 
	[omni, omni_cands, omni_stats] = red_detect_cams('omni');
	if isempty(PARAMS.omni)
		PARAMS.omni = get_ctrl_values(0); 
	end
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = 1; 
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
	imPacket.id = 1; 
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

%initialize the gui variables
function visionGuiInit
	global NOSEND; 
%	NOSEND  = 1; 
	if isempty(NOSEND)
		visionConnectGCS('192.168.10.220'); 
		'CONNECTED TO GCS'
	else
		'NOT CONNECTING TO GCS'
	end
	vision_gui

