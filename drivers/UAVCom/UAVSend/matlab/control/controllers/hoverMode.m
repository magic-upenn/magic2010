%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%this is a hovering control type
if (setitM(qn)~=7)
    setitM(qn)=7;
    
    if(seqM(qn).seq(seq_cntM(qn)).use_posdes~=1)
        qd{qn}.pos_des = qd{qn}.pos;
    elseif(~isempty(seqM(qn).seq(seq_cntM(qn)).pos(:)))
        qd{qn}.pos_des = seqM(qn).seq(seq_cntM(qn)).pos';
    end
    
    qd{qn}.euler_des = qd{qn}.euler;
    qd{qn}.vel_des = zeros(3,1);
    
    if(~isempty(seqM(qn).seq(seq_cntM(qn)).psi))
        qd{qn}.euler_des(3) = seqM(qn).seq(seq_cntM(qn)).psi;
    end
    
    %only set the gains once
    if(seqM(qn).seq(seq_cntM(qn)).resetgains==1)
        qd{qn}.onboardkp = seqM(qn).seq(seq_cntM(qn)).onboardkp;
        qd{qn}.onboardkd = seqM(qn).seq(seq_cntM(qn)).onboardkd;
    end
end

updateIntegral