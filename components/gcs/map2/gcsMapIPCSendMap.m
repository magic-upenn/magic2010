function gcsMapIPCSendMap

global GMAP GTRANSFORM GPOSE
global RNODE

for id = 1:9,
  if ~isempty(RNODE{id}),
    pF1 = RNODE{id}.pF(:,end);
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
  msg.mapData = GMAP.im;
  msg.GPOSE = GPOSE;
  msg.GTRANSFORM = GTRANSFORM;

  gcs_machine.ipcAPI('publish', 'Global_Map', serialize(msg));
end
