%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%Takeoff Mode

if (setitM(qn)~=755)
    setitM(qn)=755;
    
    qd{qn}.startpose = qd{qn}.pos - [0,0,seqM(qn).seq(seq_cntM(qn)).distbelow]';
    if ~isempty(seqM(qn).seq(seq_cntM(qn)).psi)
        qd{qn}.euler_des(3) = seqM(qn).seq(seq_cntM(qn)).psi;
    else
        qd{qn}.euler_des(3) = qd{qn}.euler;
    end
    %only set the gains once
    if(seqM(qn).seq(seq_cntM(qn)).resetgains==1)
        qd{qn}.onboardkp = seqM(qn).seq(seq_cntM(qn)).onboardkp;
        qd{qn}.onboardkd = seqM(qn).seq(seq_cntM(qn)).onboardkd;
    end
end

ti = [0,0,1]';
li =  seqM(qn).seq(seq_cntM(qn)).pos(3)-qd{qn}.startpose(3);
expectedtime = li/seqM(qn).seq(seq_cntM(qn)).speed;

if((timer(j) - seq_timeM(qn))<expectedtime);
    %on the way up
    qd{qn}.pos_des = qd{qn}.startpose + (timer(j) - seq_timeM(qn))*seqM(qn).seq(seq_cntM(qn)).speed*ti;
    qd{qn}.vel_des = seqM(qn).seq(seq_cntM(qn)).speed*ti;
else
    %at the top
    qd{qn}.pos_des = [qd{qn}.startpose(1:2);seqM(qn).seq(seq_cntM(qn)).pos(3)];
    qd{qn}.vel_des = [0,0,0]';
end


if((timer(j) - seq_timeM(qn))<(expectedtime+seqM(qn).seq(seq_cntM(qn)).yawinttime) ...
        | qd{qn}.pos(3)<(qd{qn}.startpose(3) + ...
        seqM(qn).seq(seq_cntM(qn)).distbelow + ...
        seqM(qn).seq(seq_cntM(qn)).intheight))
    %if not enough time has passed or it is below the desired height
    ki_yaw = 0;
elseif((seqM(qn).seq(seq_cntM(qn)).kpyawset))
    %turn on integral and proportional control
    seqM(qn).seq(seq_cntM(qn)).kpyawset = 0;
end

if(qd{qn}.pos(3)>(qd{qn}.startpose(3) + ...
        seqM(qn).seq(seq_cntM(qn)).distbelow + ...
        seqM(qn).seq(seq_cntM(qn)).intheight))
    %this means we are above the correct height
    updateIntegral
end

