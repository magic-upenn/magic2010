function gcsMapIPCSendMap

global GMAP GTRANSFORM GPOSE
global RNODE

global MAGIC_CONSTANTS

for id = 1:9,
  if ~isempty(RNODE{id}),
    pF1 = RNODE{id}.pF(:,end);
    
    % Hack to shift cneter for gcs gui:
    pF1(1) = pF1(1) - MAGIC_CONSTANTS.mapEastOffset;
    pF1(2) = pF1(2) - MAGIC_CONSTANTS.mapNorthOffset;

    GPOSE{id}.x = pF1(1);
    GPOSE{id}.y = pF1(2);
    GPOSE{id}.yaw = pF1(3);

    o1 = o_mult(RNODE{id}.pL(:,end), o_inv(pF1));
    GTRANSFORM{id}.dx = o1(1);
    GTRANSFORM{id}.dy = o1(2);
    GTRANSFORM{id}.dyaw = o1(3);
    
  end
end
  
global IPC_OUTPUT
if ~isempty(IPC_OUTPUT),
  msg.mapData = int8(GMAP.im);
  msg.GPOSE = GPOSE;
  msg.GTRANSFORM = GTRANSFORM;

  disp('sent map...');
  IPC_OUTPUT.ipcAPI('publish', 'Global_Map', serialize(msg));
end
