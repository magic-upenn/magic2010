%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
init_seqmsg

x1 = 0;
y1 = 0.0;
z1 = 0.2;

for c=1:numquads
    clear seq
    seq(1) = seq_default();
    seq(end).type = 755; %new takeoff maneuver
    seq(end).pos = [x1,y1,z1]; %the goal z
    seq(end).distbelow = [0.2]; %relative to the initial starting pos, below
    seq(end).intheight = [0.1]; %relative to the initial starting pos, above
    seq(end).yawinttime = 1; %time after you reach the height to start fixing yaw control
    seq(end).kpyawset = 1; %set this flag once you set kpyaw
    seq(end).safeflag = 1;
    seq(end).resetgains = 1; %reset the gains
    seq(end).psi = yawdes;
    seq(end).speed = [0.2];
    seq(end).time = t_inf;

    seq(end).useint = 1;
    
    seqM(c).seq = seq;
    seq_cntM(c) = 1;
    
end

ipcm.type = 4;
ipcm.qn = 1:numquads;
ipcm.seq = seqM;
ipcm.seqcnt = ones(numquads,1);

sipcm = serialize(ipcm);

ipcAPIPublish(msg_name,sipcm);



