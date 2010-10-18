function visionGui(ids)
	if nargin < 1
		'Need ids'
		return
	end
	global GLOBALS; 
	SetMagicPaths
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
	initComm(ids);
 	vision_gui
	'Receiving upd'
	guit = tic; 	
	utime = .5;
	last_packets = {};  
	while(1)
		  packets = UdpReceiveAPI('receive');
		  n = length(packets);
		  if n > 0
		  	%toc
			for ii=1:n
				fprintf(1,'Got packet of size %d\n',length(packets(ii).data));
				last_packets{end+1} = packets(ii).data; 
			end
			%tic
		  end
		if toc(guit) > utime
			'Updating gui'
			if numel(last_packets) > 0
				GLOBALS.updateWithPackets(last_packets); 
			end
			last_packets = {};  
			guit = tic; 
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

