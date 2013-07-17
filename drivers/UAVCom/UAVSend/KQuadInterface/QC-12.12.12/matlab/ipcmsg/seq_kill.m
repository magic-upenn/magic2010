%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%a basic startup sequence
t_inf = 1000000;
for c=1:20
    clear seq
    
    seq(1) = seq_default();

    seq(end).type = 700;
    seq(end).time = t_inf;
    seq(end).pos = [0,0,0];
    seq(end).resetgains = 0; %don't reset gains
    seq(end).trpy = [0,0,0,0]; %0 command should turn off the props
    seq(end).drpy = [0,0,0];
    seq(end).mrpy = [0,0,0];
    seq(end).onboardkp = [0,0,0];
    seq(end).onboardkd = [17,17,20];
    
    seqM(c).seq = seq;
    seq_cntM(c) = 1;
end
save seq_basic seqM
