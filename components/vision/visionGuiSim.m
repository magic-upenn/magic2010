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
	 
	ftime = .25; 
	otime = .25; 
	ftic = tic;
	otic = tic; 
	for i = 1:9
		ROBOTS(i).connected = 0;
	end
	for i = ids
		ROBOTS(i).connected = 1;
	end

	while(1)
		if toc(ftic) >= ftime
			'Get front_packet';
			packet = front_packet(); 
			GLOBALS.updateWithPacket(packet); 
			ftic = tic; 
		end
		if toc(otic) >= otime
			'Get omni_packet';
			packet = omni_packet(); 
			GLOBALS.updateWithPacket(packet); 
			otic = tic; 
		end
		tic; 
	end	

	while(1)
		for f = 1:9
			A = SIMAGES{f}; 
			for ii = randperm(9)
				quality = 50; 
				A(ii).omni  = cjpeg(A(ii).omni,quality);
				A(ii).front = cjpeg(A(ii).front,quality);
				for im = 1:3
					A(ii).omni_cands{im}  = cjpeg(A(ii).omni_cands{im},quality);
					A(ii).front_cands{im} = cjpeg(A(ii).front_cands{im},quality);
				end 
	      			packet = zlibCompress(serialize(A(ii)));
				GLOBALS.updateWithPacket(packet); 
			end 
		end
		pause(1.3)
	end

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

