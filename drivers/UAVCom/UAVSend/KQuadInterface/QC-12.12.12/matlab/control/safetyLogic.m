%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%safetyLogic
if(qd{qn}.safetymode==0)
    if((timer(j)+time0)>(qd{qn}.vtime+safety.time1))
        %time to enter the safety descent mode
        fprintf('entered safety mode, %f, %f\n',(timer(j)+time0),(qd{qn}.vtime+safety.time1));
        qd{qn}.safetymode = 1;
        
        %if the height is below a certain threshold then just kill it 
        if(qd{qn}.pos(3)<0.3)
            qd{qn}.safetymode=2;
        end
        
        qd{qn}.yawcmdsafety = qd{qn}.euler_des(3) + qd{qn}.yaw_int;
        %calculate the predicted time until impact
        t_impact = (qd{qn}.vel(3) + sqrt(qd{qn}.vel(3)^2 + 2*qd{qn}.pos(3)*seqM(qn).seq(seq_cntM(qn)).safety_accelz))...
            /(seqM(qn).seq(seq_cntM(qn)).safety_accelz);
            
        qd{qn}.killtime = timer(j) + t_impact + safety.time2;      
    end
elseif(qd{qn}.safetymode==1)
    if(timer(j)>qd{qn}.killtime)
        qd{qn}.safetymode=2;
    end
end