function gcsRecvPlannerMapFcn(data, name)

global PLANMAP

if isempty(data)
  return;
end

id = GetIdFromName(name);

fprintf('got map from robot %d\n',id);

temp = MagicGP_MAGIC_MAPSerializer('deserialize',data);
PLANMAP.map = reshape(temp.map,temp.size_x,temp.size_y);
PLANMAP.minX = temp.UTM_x;
PLANMAP.minY = temp.UTM_y;
PLANMAP.res = temp.resolution;
PLANMAP.new = 1;

