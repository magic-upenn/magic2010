function mapfsmRecvAvoidRegionsFcn(data, name)

global AVOID_REGIONS

if ~isempty(data)
  disp('got avoid regions');
  AVOID_REGIONS = deserialize(data);
end

