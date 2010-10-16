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
			VisionMsgHandler(packet);
			ftic = tic; 
		end
		if toc(otic) >= otime
			'Get omni_packet'
			packet = omni_packet(); 
			VisionMsgHandler(packet);
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
				VisionMsgHandler(packet);
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
% Set up the figure

function VisionMsgHandler(imPacket); 
	global IMAGES GLOBALS;
	stats = whos('imPacket'); 
	stats.bytes
	imPacket = deserialize(zlibUncompress(imPacket));
	IMAGES(imPacket.id).t = imPacket.t; 
	IMAGES(imPacket.id).pose = imPacket.pose;
	IMAGES(imPacket.id).front_angle = imPacket.front_angle; 
	if strcmp(imPacket.type,'FrontVision')
		IMAGES(imPacket.id).front = djpeg(imPacket.front);
		for im = 1:3
			IMAGES(imPacket.id).front_cands{im} = djpeg(imPacket.front_cands{im});
		end 
		IMAGES(imPacket.id).front_stats = imPacket.front_stats; 
		IMAGES(imPacket.id).scanH = imPacket.scanH; 
		IMAGES(imPacket.id).scanV = imPacket.scanV; 
		if ~isempty(imPacket.scanV)
			IMAGES(imPacket.id).scanV =  imresize(fliplr(imPacket.scanV.ranges(445:628)),[1,15],'nearest'); 
		else
			IMAGES(imPacket.id).scanV = zeros([1,15]); 
		end
		%Hokuyu: step = 1081, step = 0.0044, fov = 270
		if ~isempty(imPacket.scanH)
			IMAGES(imPacket.id).scanH =  imresize(fliplr(imPacket.scanH.ranges(405:675)),[1,15],'nearest'); 
		else
			IMAGES(imPacket.id).scanH = zeros([1,15]); 
		end
	end
	if strcmp(imPacket.type,'OmniVision')
		IMAGES(imPacket.id).omni = djpeg(imPacket.omni);
		for im = 1:3
			IMAGES(imPacket.id).omni_cands{im}  = djpeg(imPacket.omni_cands{im});
		end 
		IMAGES(imPacket.id).omni_stats = imPacket.omni_stats; 
	end
	GLOBALS.vision_fns.updateGui(imPacket.id);  
