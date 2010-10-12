function visionGui
	SetMagicPaths
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
	visionGuiInit;
	%Setting up icp'
	%while(1)
	%  fprintf(1,'.');
	%    masterReceiveFromRobots(10);
	%    pause(0.05);
	%end

	'Setting up upd'
	addr = '192.168.10.221';
	port = 12345;
	UdpReceiveAPI('connect',addr,port);
	'Receiving upd'
	while(1)
	  packets = UdpReceiveAPI('receive');
	  n = length(packets);
	  if n > 0
	    for ii=1:n
	      fprintf(1,'got packet of size %d\n',length(packets(ii).data));
	      packet = deserialize(zlibUncompress(packets(ii).data));
	      switch(packet.type)
		case 'Vision'
		  VisionMsgHandler(packet);
	      end
	    end
	  end
	  pause(0.01)
	end

%initialize the gui variables
function visionGuiInit
	global IMAGES STATIC_OOI ROBOTS
	visionConnectGCS('192.168.10.220'); 
	nRobots = 10;
	%ids = [4 6 7]; % list of ID's of available robots
	ids = [2 5 6 7 ]; % list of ID's of available robots

	ipcInit;
%	masterConnectRobots(ids,'127.0.0.1');
	masterConnectRobots(ids);

	for ii=1:length(ROBOTS)
	  if (ROBOTS(ii).connected == 1)
	%    ROBOTS(ii).ipcAPI('define',sprintf('Robot%d/CamParam',ii));
	    ROBOTS(ii).ipcAPI('define',sprintf('Robot%d/Look_Msg',ii));
	  end
	end

	if false
	messages = {'Image'};
	handles  = {@ipcRecvImageFcn};

	%subscribe to messages
	masterSubscribeRobots(messages,handles,[1]);
	end

	vision_gui
% Set up the figure

function ipcRecvImageFcn(msg,name)
	global IMAGES PLOTHANDLES GUI
	imPacket = deserialize(msg);
	VisionMsgHandler(imPacket); 

function VisionMsgHandler(imPacket); 
	global IMAGES
	%fprintf(1,'got image name %s\n',name);
	IMAGES(imPacket.id) = imPacket;
	IMAGES(imPacket.id).omni = djpeg(imPacket.omni);
	IMAGES(imPacket.id).front = djpeg(imPacket.front);
	for im = 1:3
		IMAGES(imPacket.id).omni_cands{im}  = djpeg(imPacket.omni_cands{im});
		IMAGES(imPacket.id).front_cands{im} = djpeg(imPacket.front_cands{im});
	end 
	omni = IMAGES(imPacket.id).omni; 
	front = IMAGES(imPacket.id).front; 
	omni_cand = IMAGES(imPacket.id).omni_cands{1}; 
	front_cand = IMAGES(imPacket.id).front_cands{1}; 
	IMAGES(imPacket.id).pose = imPacket.pose;
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
%	IMAGES(imPacket.id).scanV = imPacket.scanV.ranges;%  imresize(imPacket.scanV.ranges(241:601+240),[1,15],'nearest'); 
	global GLOBALS;
	GLOBALS.vision_fns.updateGui();  


