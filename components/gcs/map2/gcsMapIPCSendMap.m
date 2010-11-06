function gcsMapIPCSendMap

global GMAP
global GTRANSFORM GPOSE
global RNODE

global MAGIC_CONSTANTS

gtIPC = cell(9,1);
gpIPC = cell(9,1);

for id = 1:9,
  if ~isempty(RNODE{id}),
    pL1 = RNODE{id}.pL(:,end);
    pF1 = o_mult(GTRANSFORM{id}, pL1);

    % Hack to shift cneter for gcs gui:
    pFshift = pF1;
    pFshift(1) = pF1(1) - MAGIC_CONSTANTS.mapEastOffset;
    pFshift(2) = pF1(2) - MAGIC_CONSTANTS.mapNorthOffset;

    gpIPC{id}.x = pFshift(1);
    gpIPC{id}.y = pFshift(2);
    gpIPC{id}.yaw = pFshift(3);

    o1 = o_mult(pl1, o_inv(pFshift));
    gtIPC{id}.dx = o1(1);
    gtIPC{id}.dy = o1(2);
    gtIPC{id}.dyaw = o1(3);    
  end
end
  
global IPC_OUTPUT
if ~isempty(IPC_OUTPUT),
  msg.mapData = int8(GMAP.im);
  msg.GPOSE = gpIPC;
  msg.GTRANSFORM = gtIPC;

  disp('sent map...');
  IPC_OUTPUT.ipcAPI('publish', 'Global_Map', serialize(msg));
end
