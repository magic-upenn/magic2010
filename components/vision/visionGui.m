function visionGui
	SetMagicPaths
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/uvcCam' ] )
	addpath( [ getenv('MAGIC_DIR') '/trunk/components/vision/RedDetect' ] )
	visionGuiInit;

	while(1)
	  fprintf(1,'.');
	    masterReceiveFromRobots(10);
	    pause(0.05);
	end


%initialize the gui variables
function visionGuiInit
	global IMAGES STATIC_OOI ROBOTS

	nRobots = 10;
	ids = [4]; % list of ID's of available robots
	ipcInit;

%	masterConnectRobots(ids,'127.0.0.1');
	masterConnectRobots(ids);

	for ii=1:length(ROBOTS)
	  if (ROBOTS(ii).connected == 1)
	%    ROBOTS(ii).ipcAPI('define',sprintf('Robot%d/CamParam',ii));
	    ROBOTS(ii).ipcAPI('define',sprintf('Robot%d/Look_Msg',ii));
	  end
	end

	messages = {'Image'};
	handles  = {@ipcRecvImageFcn};

	%subscribe to messages
	masterSubscribeRobots(messages,handles,[1]);

	%setup local IPC to send confirmed OOI to Mapping Console 
%	ipcAPIDefine('ConfirmedOOI');

	vision_gui
% Set up the figure

function ipcRecvImageFcn(msg,name)
	global IMAGES PLOTHANDLES GUI
	%fprintf(1,'got image name %s\n',name);
	imPacket = deserialize(msg);
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
		global B; 
		B = imPacket.scanH
		IMAGES(imPacket.id).scanH =  imresize(fliplr(imPacket.scanH.ranges(405:675)),[1,15],'nearest'); 
	else
		IMAGES(imPacket.id).scanH = zeros([1,15]); 
	end
%	IMAGES(imPacket.id).scanV = imPacket.scanV.ranges;%  imresize(imPacket.scanV.ranges(241:601+240),[1,15],'nearest'); 
	global GLOBALS;
	GLOBALS.vision_fns.updateGui();  

function ipcRecvStaticOoiFcn(msg,name)
	global  IMAGES STATIC_OOI GUI
	%fprintf(1,'got static ooi\n');
	OOIpacket = deserialize(msg);
	STATIC_OOI(OOIpacket.id) = OOIpacket;
	subplot(2,3,OOIpacket.id+3);
	imshow(IMAGES(OOIpacket.id).jpg); axis image;
	hold on;
		BB = OOIpacket.OOI.BoundingBox;
		line([BB(1),BB(1)+BB(3)],[BB(2),BB(2)],'Color','g');
		line([BB(1)+BB(3),BB(1)+BB(3)],[BB(2),BB(2)+BB(4)],'Color','g');
		line([BB(1),BB(1)],[BB(2),BB(2)+BB(4)],'Color','g');
		line([BB(1),BB(1)+BB(3)],[BB(2)+BB(4),BB(2)+BB(4)],'Color','g');
		text(BB(1),BB(2),sprintf('%2.2f',OOIpacket.OOI.distance),'color','g');
		text(BB(1),BB(2)+BB(4),sprintf('%2.2f',OOIpacket.OOI.angle),'color','g');
	hold off;
	set(GUI.hConfOOI(OOIpacket.id),'Visible','on');

function manualOOI(hObj,eventdata)
	id = get(hObj,'UserData');
	%fprintf(1,'Clicked Manual OOI %d\n',id);
	[xcrop,ycrop] = ginput(2);
	rect = [min(xcrop) min(ycrop) abs(xcrop(1)-xcrop(2)) abs(ycrop(1)-ycrop(2))];
	distance = GetDistfromYheight(abs(ycrop(1)-ycrop(2)))
	centroid = [mean(xcrop) mean(ycrop)];
	angle = atand((centroid(1)-256/2)/(72/44*256/2))
	    confOOI.OOI.area = [];
	    confOOI.OOI.centroid = centroid;
	    confOOI.OOI.boundingBox = [];
	    confOOI.OOI.BoundingBox = rect;
	    confOOI.OOI.Extent = [];
	    confOOI.OOI.Cr_mean = [];
	    confOOI.OOI.distance = distance;
	    confOOI.OOI.angle = angle;
	    confOOI.OOI.redbinscore = [];
	    confOOI.id = id;
	    confOOI.t = [];
	    confOOI.POSE = [];

	    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
	    disp('Confirmed OOI sent');

function confirmOOI(hObj,eventdata)
	global STATIC_OOI GUI
	if eventdata.Character == '1'
	    confOOI = STATIC_OOI(1)
	    set(GUI.hConfOOI(1),'Visible','off');
	    subplot(2,3,4); image([]); axis equal; axis([1 256 1 192]); axis ij;
	    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
	    disp('Confirmed OOI sent');
	end
	if eventdata.Character == '2'
	    confOOI = STATIC_OOI(2)
	    set(GUI.hConfOOI(2),'Visible','off');
	    subplot(2,3,5); image([]); axis equal; axis([1 256 1 192]); axis ij;
	    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
	    disp('Confirmed OOI sent');
	end
	if eventdata.Character == '3'
	    confOOI = STATIC_OOI(3)
	    set(GUI.hConfOOI(3),'Visible','off');
	    subplot(2,3,6); image([]); axis equal; axis([1 256 1 192]); axis ij;
	    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
	    disp('Confirmed OOI sent');
	end

function updateCam(hObj,eventdata)
	global ROBOTS
	id = get(hObj,'UserData');
	newYmean = str2double(get(hObj,'string'));
	if isnan(newYmean)
		errordlg('You must enter a numeric value','Bad Input','modal')
	return
	end
	ROBOTS(id).ipcAPI('publish',sprintf('Robot%d/CamParam',id),serialize(newYmean));

