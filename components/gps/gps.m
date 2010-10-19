function gps(tUpdate)
clear all;
SetMagicPaths

if nargin < 1,
  tUpdate = 0.01;
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
addpath( [ getenv('VIS_DIR') '/ipc' ] )

GPS.ipcMsgName = GetMsgName('GPS');

%connect to ipc
ipcAPIConnect;
ipcAPISubscribe(GPS.ipcMsgName);


% Setup figure
figure(1)
clf;
set(gcf,'NumberTitle','off','Name','GPS Status',...
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
GPS.hNumSat = uicontrol('Style','edit','Units','normalized', ...
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
GPS.x = [];
GPS.y = [];
GPS.zone = [];
GPS.traj = [];
GPS.trajMap = [];

%{
figure(2)
clf(gcf);
im = imread('upenn_small.jpg');
GPS.hOverhead=image(im(end:-1:1,:,:)); hold on;
set(gca,'ydir','normal');
GPS.hTrajMap = plot3(0,0,0,'.');
hold off;
%}


function gpsUpdate
global GPS
msgs = ipcAPI('listenClear',10);
len = length(msgs);
if len > 0
  for mi=1:len
    switch msgs(mi).name
      case GPS.ipcMsgName
        fprintf(1,'.');
        
        gpsPacket   = MagicGpsASCIISerializer('deserialize',msgs(mi).data);
        gpsString = char(gpsPacket.data);
        checksumOk = nmeaChecksum(gpsString);
        if (checksumOk == 1)
          fprintf(1,'%s',gpsString);
          GPS.numPackets =  GPS.numPackets + 1;
          GpsNMEAParser(gpsString);
        else
          warning('gps checksum error');
          GPS.numErrors = GPS.numErrors+1;
          fprintf(1,'%s\n',gpsString);
        end
      otherwise
        fprintf(1,'WARNING: unknown message type\n');
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
  case '$GPRMC'
    GpsNMEAParseRMC(line);
end


function GpsNMEAParseRMC(line)
global GPS
packet = textscan(line,'%s','delimiter',',*');
packet = packet{1};

%convert values to double (some will be NaN)
dpacket = str2double(packet);

GPS.utc_time  = dpacket(2);
rmc_valid     = packet(3);
if (strcmp(rmc_valid,'A') ==1) %A for valid, V for invalid
  GPS.valid = 1;
else
  GPS.valid = 0;
end

GPS.lat       = floor(dpacket(4)/100) + rem(dpacket(4),100)/60;
GPS.NS        = packet{5}; %north/south
if (strcmp(GPS.NS,'S')) GPS.lat = -GPS.lat; end
GPS.lon       = floor(dpacket(6)/100) + rem(dpacket(6),100)/60;
GPS.EW        = packet{7}; %east/west
if (strcmp(GPS.EW,'W')) GPS.lon = -GPS.lon; end
GPS.speed     = dpacket(8) * 0.514444; %convert from knots to m/s
GPS.heading   = dpacket(9);
GPS.date      = dpacket(10);
GPS.magVarDeg = dpacket(11);
GPS.magVarDir = packet{12};
GPS.mode      = packet{13};

function GpsNMEAParseGGA(line)
global GPS
packet = textscan(line,'%s','delimiter',',*');
packet = packet{1};

%convert values to double (some will be NaN)
dpacket = str2double(packet);

%some of the below values will be used from RMC packet
%{
GPS.utc_time = dpacket(2);
GPS.lat      = floor(dpacket(3)/100) + rem(dpacket(3),100)/60;
GPS.NS       = packet{4}; %north/south
if (strcmp(GPS.NS,'S')) GPS.lat = -GPS.lat; end
GPS.lon      = floor(dpacket(5)/100) + rem(dpacket(5),100)/60;
GPS.EW       = packet{6}; %east/west
if (strcmp(GPS.EW,'W')) GPS.lon = -GPS.lon; end
%}
GPS.pos_fix  = dpacket(7);
GPS.num_sat  = dpacket(8);
GPS.hdop     = dpacket(9);
GPS.msl_alt  = dpacket(10);
%units for altitude ??
GPS.geoid_sep= dpacket(12);
%units for separation ??
GPS.age_diff = dpacket(14);
GPS.diff_ref_id = dpacket(15);
    

