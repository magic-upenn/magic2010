function mapfsmRecvVelTracks(data, name)

global TRACKS

if ~isempty(data)
  TRACKS = deserialize(data);
end
