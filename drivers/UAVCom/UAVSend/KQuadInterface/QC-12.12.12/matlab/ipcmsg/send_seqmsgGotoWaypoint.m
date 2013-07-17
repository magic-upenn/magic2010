%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
init_seqmsg

%the local shape of the team
L = 0.5;
shape = [0,0,0;...
0,L,0;...
-L,0,0;...
0,-L,0];

%the global position of the shape
xshape = 0;
yshape = 0.0;
zshape = 0.7;

speed = 0.5;
accelrate = 0.5;

for jj=1:numquads;
    xf(jj) = xshape + shape(jj,1);
    yf(jj) = yshape + shape(jj,2);
    zf(jj) = zshape + shape(jj,3);
end

triggertime = GetUnixTime+1;

for c=1:numquads
    clear seq
    seq(1) = seq_default();
    seq(end).type = 7; %hover with i
    seq(end).pos = [];
    seq(end).resetgains = 1;
    seq(end).psi = yawdes;
    seq(end).time = t_inf;
    seq(end).unixtime = triggertime;
    seq(end).useint = 1;

    seq(end+1) = seq_default();
    seq(end).type = 55;
    seq(end).pos =  [];
    seq(end).psi = yawdes;
    seq(end).speed = [speed];
    seq(end).accelrate = accelrate;
    seq(end).time = [];
    seq(end).useint = 0;
    
    seq(end+1) = seq_default();
    seq(end).type = 7; %hover with i
    seq(end).pos = [xf(c),yf(c),zf(c)];
    seq(end).resetgains = 1;
    seq(end).psi = yawdes;
    seq(end).time = t_inf;
    seq(end).useint = 1;
    seq(end).use_posdes = 1;

    seqM(c).seq = seq;
    seq_cntM(c) = 1;   
end

%send through seqM
ipcm.type = 4;
ipcm.qn = 1:numquads;
ipcm.seq = seqM;
ipcm.seqcnt = ones(numquads,1);

sipcm = serialize(ipcm);

ipcAPIPublish(msg_name,sipcm);



