%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
init_seqmsg

for c=1:numquads
    clear seq
    seq(1) = seq_default();

    %just sit and idle
    seq(end).type = 700;
    seq(end).time = t_inf;
    seq(end).resetgains = 1;
    seq(end).trpy = [1,0,0,0]; %100 grams
    seq(end).drpy = [0,0,0];
    seq(end).onboardkp = [0,0,0];
    seq(end).onboardkd = [0,0,0];
    seq(end).zeroint = 1;
    
    seqM(c).seq = seq;
    seq_cntM(c) = 1;
end

ipcm.type = 4;
ipcm.qn = 1:numquads;
ipcm.seq = seqM;
ipcm.seqcnt = ones(numquads,1);

sipcm = serialize(ipcm);

ipcAPIPublish(msg_name,sipcm);



