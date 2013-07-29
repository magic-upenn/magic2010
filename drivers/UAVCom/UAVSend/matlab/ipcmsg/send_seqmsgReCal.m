%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
init_seqmsg

for c=1:numquads
    clear seq
    seq(1) = seq_default();

    %recalibrate the quads
    seq(end).type = 700;
    seq(end).time = 1;
    seq(end).resetgains = 1;
    seq(end).trpy = [2,0,0,0];
    seq(end).onboardkp = [0,0,0];
    seq(end).onboardkd = [0,0,0];
    seq(end).zeroint = 1;
    
    seq(end+1) = seq_default();
    seq(end).type = 700;
    seq(end).time = t_inf;
    seq(end).resetgains = 1; %don't reset gains
    seq(end).trpy = [0,0,0,0]; %100 grams
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



