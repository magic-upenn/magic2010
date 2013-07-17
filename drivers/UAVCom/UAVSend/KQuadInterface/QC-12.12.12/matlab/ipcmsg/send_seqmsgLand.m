%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
init_seqmsg

zland = 0; %height at which you want to land

for c=1:numquads
    clear seq
    seq(1) = seq_default();
    
    %descend
    seq(end).type = 55;
    seq(end).skipx = 1;
    seq(end).skipy = 1;
    seq(end).skipz = 0;
    seq(end).psi = yawdes;
    seq(end).speed = [0.3];
    seq(end).useint = 0;
    seq(end).accelrate = 0.5;
    seq(end).use_posdes = 1;

    %turn props off
    seq(end+1) = seq_default();
    seq(end).type = 700;
    seq(end).time = t_inf;
    seq(end).pos = [0,0,zland];
    seq(end).resetgains = 0; %don't reset gains
    seq(end).trpy = [0,0,0,0]; %0 command should turn off the props
    
    seqM(c).seq = seq;
    seq_cntM(c) = 1;
end

ipcm.type = 4;
ipcm.qn = 1:numquads;
ipcm.seq = seqM;
ipcm.seqcnt = ones(numquads,1);

sipcm = serialize(ipcm);

ipcAPIPublish(msg_name,sipcm);
