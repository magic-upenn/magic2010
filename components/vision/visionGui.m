function visionGui(ids)
	globals GLOBALS; 
	SetMagicPaths
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
	initComm(ids);
 	vision_gui
	'Receiving upd'
	while(1)
		  packets = UdpReceiveAPI('receive');
		  n = length(packets);
		  if n > 0
			for ii=1:n
				fprintf(1,'Got packet of size %d\n',length(packets(ii).data));
				assert(strcmp(imPacket.type,'OmniVision') | strcmp(imPacket.type,'FrontVision')); 
				GLOBALS.updateWithPacket(packets(ii).data); 
			end
		  end
	end

%initialize the gui variables
function initComm(ids)
	global IMAGES ROBOTS
	'Connecting to GCS'
	visionConnectGCS('192.168.10.220'); 
	'Initializing IPC'
	ipcInit;
%	masterConnectRobots(ids,'127.0.0.1');
	masterConnectRobots(ids);
	
	'Setting up upd'
	addr = '192.168.10.221';
	port = 12345;
	UdpReceiveAPI('connect',addr,port);

