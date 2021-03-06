function gps(tUpdate)

if nargin < 1,
  tUpdate = 0.1;
end

gpsStart;

loop = 1;
while (loop),
  pause(tUpdate);
  gpsUpdate;
end

gpsStop;


function gpsStart
global GPS
SetMagicPaths;

gpsMsgName = GetMsgName('GPS');

%connect to ipc
ipcAPIConnect;
ipcAPISubscribe(gpsMsgName);


% Setup figure
clf;
set(gcf,'NumberTitle','off','Name','RT3000',...
	'Position',[500 500 300 200]);

% Packet status
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.5 .7 .25 .1], 'String', 'Pkts');
GPS.hNumPackets = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.75 .7 .25 .1], 'String', '0');
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.5 .6 .25 .1], 'String', 'Errors');
GPS.hErrors = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.75 .6 .25 .1], 'String', '0');

% Speedometer
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.25 .8 .1 .1], 'String', 'm/s');
GPS.hSpeed = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.05 .8 .2 .1], 'String', '');
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.25 .7 .1 .1], 'String', 'm');
GPS.hDist = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.05 .7 .2 .1], 'String', '');
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.25 .6 .1 .1], 'String', 'deg');
GPS.hHeading = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.05 .6 .2 .1], 'String', '');

% GPS status
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.05 .4 .2 .1], 'String', '# Sats');
GPS.hNumObs = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.25 .4 .25 .1], 'String', '');
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.05 .3 .2 .1], 'String', 'Pos Update');
GPS.hPosMode = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.25 .3 .25 .1], 'String', '');
uicontrol('Style','text','Units','normalized', ...
	  'Position',[.05 .2 .2 .1], 'String', 'Vel Update');
GPS.hVelMode = uicontrol('Style','edit','Units','normalized', ...
		      'Position',[.25 .2 .25 .1], 'String', '');


GPS.numPackets = 0;
GPS.numErrors  = 0;



function gpsUpdate
global GPS
msgs = ipcAPIReceive(10);
len = length(msgs);
if len > 0
  for i=1:len
    dpacket   = DeserializeIpcRawDynamixelPacket(msgs(i).data);
    gpsString = char(DynamixelPacketGetPayload(dpacket.data));
    checksumOk = nmeaChecksum(gpsString);
    if (checksumOk == 1)
      GpsNMEAParser(gpsString);
    else
      warning('gps checksum error');
      GPS.numErrors = GPS.numErrors+1;
    end
  end
end



function GpsNMEAParser(line)
if ~isa(line,'char')
  error('gps line must be a string')
end

type = strtok(line,',');

switch type
  case '$GPGGA'
    GpsNMEAParseGGA(line);
end



function GpsNMEAParseGGA(line)
global GPS
packet = textscan(line,'%s','delimiter',',*');
packet = packet{1};

%convert values to double (some will be NaN)
dpacket = str2double(packet);

GPS.utc_time = dpacket(2);
GPS.lat      = dpacket(3);
%north/south
GPS.lon      = dpacket(5);
%east/west
GPS.pos_fix  = dpacket(7);
GPS.nsat     = dpacket(8);
GPS.hdop     = dpacket(9);
GPS.msl_alt  = dpacket(10);
%units for altitude
GPS.geoid_sep= dpacket(12);
%units for separation
GPS.age_diff = dpacket(14);
GPS.diff_ref_id = dpacket(15);

GPS.numPackets =  GPS.numPackets + 1;

set(GPS.hNumPackets,'String',num2str(GPS.numPackets));
set(GPS.hErrors,'String',num2str(GPS.numErrors));


drawnow;




    

