function visionGuiSim
	SetMagicPaths
	visionGuiInit;
	global SIMAGES GLOBALS
	ftime = .25; 
	otime = .25; 
	ftic = tic;
	otic = tic; 
	while(1)
		if toc(ftic) >= ftime
			'Get front_packet'
			packet = front_packet(); 
			GLOBALS.updateWithPacket(packet); 
			ftic = tic; 
		end
		if toc(otic) >= otime
			'Get omni_packet'
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
	[omni, omni_cands, omni_stats] = red_detect_cams('omni');
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = 1; 
	imPacket.type = 'OmniVision';  
	imPacket.t  = GetUnixTime();
	imPacket.omni = cjpeg(omni,quality);
	imPacket.front_angle = 0;
	for im = 1:3
		imPacket.omni_cands{im}  = cjpeg(omni_cands{im},quality);
	end 
	imPacket.omni_stats = omni_stats;
	data.x = 0; 
	data.y = 0; 
	data.yaw = 0; 
	imPacket.pose = data; 
	imPacket = zlibCompress(serialize(imPacket));

function imPacket = front_packet()
	[front, front_cands, front_stats] = red_detect_cams('front');
	quality = 80;  
	%%%%% send compressed jpg image through IPC %%%%%
	imPacket.id = 1; 
	imPacket.type = 'FrontVision';  
	imPacket.t  = GetUnixTime();
	imPacket.front = cjpeg(front,quality);
	imPacket.front_angle = 0;
	imPacket.scanH.ranges = rand(1,1081);
	imPacket.scanV.ranges = rand(1,1081);
	for im = 1:3
		imPacket.front_cands{im} = cjpeg(front_cands{im},quality);
	end 
	imPacket.front_stats = front_stats;
	data.x = 0; 
	data.y = 0; 
	data.yaw = 0; 
	imPacket.pose = data; 
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

