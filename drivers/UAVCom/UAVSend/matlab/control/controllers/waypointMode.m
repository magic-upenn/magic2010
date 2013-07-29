%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%this is a simple waypoint controller
%we ramp up to the desired speed at the desired acceleration
%we ramp down to 0 at the desired accleration

if (setitM(qn)~=55 & isempty(seqM(qn).seq(seq_cntM(qn)).pos(:)))
    setitM(qn)=55;
    
    if(seqM(qn).seq(seq_cntM(qn)).use_posdes==1)
        qd{qn}.startpose = qd{qn}.pos_des;
    else
        qd{qn}.startpose = qd{qn}.pos;
    end
    
    if(~isempty(seqM(qn).seq(seq_cntM(qn)).psi))
        qd{qn}.euler_des(3) = seqM(qn).seq(seq_cntM(qn)).psi;
        
    else
        qd{qn}.euler_des(3) = psiM(qn);
    end
    
elseif(setitM(qn)~=55)
    qd{qn}.startpose = seqM(qn).seq(seq_cntM(qn)).pos(:);
    setitM(qn)=55;
    
    if(~isempty(seqM(qn).seq(seq_cntM(qn)).psi))
        qd{qn}.euler_des(3) = seqM(qn).seq(seq_cntM(qn)).psi;
    else
        qd{qn}.euler_des(3) = psiM(qn);
    end
    
end

%look to the next segment for the desired position
desiredpos = seqM(qn).seq(seq_cntM(qn)+1).pos';

%allow the desired position to be the actual position
if(seqM(qn).seq(seq_cntM(qn)).skipx)
    desiredpos(1) = qd{qn}.startpose(1);
end
if(seqM(qn).seq(seq_cntM(qn)).skipy)
    desiredpos(2) = qd{qn}.startpose(2);
end
if(seqM(qn).seq(seq_cntM(qn)).skipz)
    desiredpos(3) = qd{qn}.startpose(3);
end

%compute the vector to the desired position
ti = desiredpos-qd{qn}.startpose;
li = sqrt(sum(ti.*ti));

if(li<1e-3)
    ti = [1,0,0]';
else
    ti = ti./li;
end

timenow = GetUnixTime-time0;

%find the desired velocity and position
if(isempty(seqM(qn).seq(seq_cntM(qn)).accelrate))
    %instantaneously change speed;
    
    expectedtime = li/seqM(qn).seq(seq_cntM(qn)).speed;
    seqM(qn).seq(seq_cntM(qn)).time = expectedtime;
    
    qd{qn}.pos_des = qd{qn}.startpose + (timenow - seq_timeM(qn))*seqM(qn).seq(seq_cntM(qn)).speed*ti;
    
    qd{qn}.vel_des = seqM(qn).seq(seq_cntM(qn)).speed*ti;
else
    %accelerate to the desired speed at some rate
    
    t_ramp = seqM(qn).seq(seq_cntM(qn)).speed/seqM(qn).seq(seq_cntM(qn)).accelrate;
    d_ramp = seqM(qn).seq(seq_cntM(qn)).speed^2/(seqM(qn).seq(seq_cntM(qn)).accelrate*2);
    if(li<(2*d_ramp))
        %just ramp up then ramp down immediately cause it is too short
        t_miniramp = sqrt(2*(li/2)/seqM(qn).seq(seq_cntM(qn)).accelrate);
        expectedtime = 2*t_miniramp;
        
        if((timenow-seq_timeM(qn))<t_miniramp)
            t_after = timenow-seq_timeM(qn);
            voft = seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after);
            doft = seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after)^2/2;
        else
            t_after = timenow-seq_timeM(qn)-t_miniramp;
            voft = t_miniramp * seqM(qn).seq(seq_cntM(qn)).accelrate - seqM(qn).seq(seq_cntM(qn)).accelrate * t_after;
            doft = li/2 + t_miniramp * seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after)...
                - seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after)^2/2;
        end
    else
        %there is some stall time in the middle where we hold speed
        d_middle = li-2*d_ramp;
        t_middle = d_middle/seqM(qn).seq(seq_cntM(qn)).speed;
        expectedtime = 2*t_ramp + t_middle;
        
        if((timenow-seq_timeM(qn))<t_ramp)
            t_after = timenow-seq_timeM(qn);
            voft = seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after);
            doft = seqM(qn).seq(seq_cntM(qn)).accelrate * (t_after)^2/2;
        elseif((timenow-seq_timeM(qn))<(t_ramp + t_middle))
            t_after = timenow-seq_timeM(qn) - t_ramp;
            voft = seqM(qn).seq(seq_cntM(qn)).speed;
            doft = d_ramp + voft*t_after;
        else
            t_after = timenow - seq_timeM(qn) - t_ramp - t_middle;
            voft = seqM(qn).seq(seq_cntM(qn)).speed - seqM(qn).seq(seq_cntM(qn)).accelrate*t_after;
            doft = d_ramp + d_middle + seqM(qn).seq(seq_cntM(qn)).speed*t_after...
                - seqM(qn).seq(seq_cntM(qn)).accelrate*(t_after^2) /2;
        end
        
    end
    seqM(qn).seq(seq_cntM(qn)).time = expectedtime;
        
    qd{qn}.pos_des = qd{qn}.startpose + doft*ti;
    
    qd{qn}.vel_des = voft*ti;

end

updateIntegral
