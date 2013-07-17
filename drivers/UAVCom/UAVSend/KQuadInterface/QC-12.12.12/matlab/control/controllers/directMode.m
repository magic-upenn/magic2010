%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
if (setitM(qn)~=700)
    setitM(qn)=700;
    
    %only set the gains once
    if(seqM(qn).seq(seq_cntM(qn)).resetgains==1)
        qd{qn}.onboardkp = seqM(qn).seq(seq_cntM(qn)).onboardkp;
        qd{qn}.onboardkd = seqM(qn).seq(seq_cntM(qn)).onboardkd;
    end
    
    if(seqM(qn).seq(seq_cntM(qn)).zeroint)
        %zero out the integral terms
        qd{qn}.phi_int = 0;
        qd{qn}.theta_int = 0;
        qd{qn}.th_int = 0;
        qd{qn}.yaw_int = 0;
        qd{qn}.safeflag = 1;
    end  
end

trpy = seqM(qn).seq(seq_cntM(qn)).trpy;
if(~isempty(seqM(qn).seq(seq_cntM(qn)).trpyuseint))
    if(seqM(qn).seq(seq_cntM(qn)).trpyuseint(1))
        trpy(1) = qd{qn}.th_int;
    end
    if(seqM(qn).seq(seq_cntM(qn)).trpyuseint(2))
        trpy(2) = qd{qn}.phi_int;
    end
    if(seqM(qn).seq(seq_cntM(qn)).trpyuseint(3))
        trpy(3) = qd{qn}.theta_int;
    end
    if(seqM(qn).seq(seq_cntM(qn)).trpyuseint(4))
        trpy(4) = qd{qn}.yaw_int;
    end
end
drpy = [0,0,0];