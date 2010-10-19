function GpsNMEAParser(line)
global GPS
if ~isa(line,'char')
  error('gps line must be a string')
end

if ~isfield(GPS,'numPackets')
  GPS.numPackets = 0;
  GPS.numErrors  = 0;
end

checksumOk = nmeaChecksum(line);
if (checksumOk == 1)
  %fprintf(1,'%s',line);
  GPS.numPackets =  GPS.numPackets + 1;
else
  warning('gps checksum error');
  GPS.numErrors = GPS.numErrors+1;
  fprintf(1,'%s\n',line);
  return;
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

GPS.utcTime  = dpacket(2);
rmcValid     = packet(3);
if (strcmp(rmcValid,'A') ==1) %A for valid, V for invalid
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
GPS.t         = GetUnixTime();


%NAN checking
if isnan(GPS.lat), GPS.lat = []; end
if isnan(GPS.lon), GPS.lon = []; end
if isnan(GPS.speed), GPS.speed = []; end
if isnan(GPS.heading), GPS.heading = []; end
if isnan(GPS.magVarDeg), GPS.magVarDeg = []; end
if isnan(GPS.mode), GPS.mode = []; end

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
GPS.posFix  = dpacket(7); %0=no fix; 1= GPS SPS mode, valid fix; 2=DGPS, valid fix..
GPS.numSat  = dpacket(8);
GPS.hdop     = dpacket(9);  %units???
GPS.mslAlt  = dpacket(10); %meters
GPS.geoidSep= dpacket(12); %meters

%NAN checking
if isnan(GPS.mslAlt), GPS.mslAlt = []; end
if isnan(GPS.geoidSep), GPS.geoidSep = []; end
