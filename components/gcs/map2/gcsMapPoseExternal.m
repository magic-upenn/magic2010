function gcsMapPoseExternal(id, pkt)

global RPOSE

gps = pkt.gps;
pose.pL = [pkt.x; pkt.y; pkt.yaw];
      
if ~isempty(gps.lat),
  [utmE, utmN] = deg2utm(gps.lat, gps.lon);
  if ~isempty(gps.heading),
    utmA = modAngle(pi/2-gps.heading);
  else
    utmA = NaN;
  end
  pose.pGps = [utmE; utmN; utmA];
else
  pose.pGps = repmat(NaN,[3 1]);
end
pose.gps = gps;

% Check number of satellites, HDOP, and heading for validity
if (~isempty(gps.heading) && ...
    (gps.numSat >= 10) && ...
    (gps.hdop < 1.1))
  pose.gpsValid = 1;
else
  pose.gpsValid = 0;
end

RPOSE{id} = pose;
