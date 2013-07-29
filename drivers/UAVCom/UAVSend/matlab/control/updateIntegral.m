%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%updateIntegral

if(j>1)
    delTint = timer(j)-timer(j-1);
else
    delTint = 0;
end

if(qd{qn}.safetymode==0)
    if(seqM(qn).seq(seq_cntM(qn)).useint)
        %associate integral errors with body and not world
        xybodyint = delTint * [cos(qd{qn}.euler(3)), sin(qd{qn}.euler(3));...
            -sin(qd{qn}.euler(3)), cos(qd{qn}.euler(3))]...
            *[qd{qn}.pos_des(1)-qd{qn}.pos(1);qd{qn}.pos_des(2)-qd{qn}.pos(2)];
        zbodyint = delTint * (qd{qn}.pos_des(3)-qd{qn}.pos(3));
        
        psi_diff = mod(qd{qn}.euler_des(3) - qd{qn}.euler(3),2*pi);
        psi_diff = psi_diff - (psi_diff>pi)*2*pi;
        yawint = delTint*psi_diff;
        
        qd{qn}.phi_int = qd{qn}.phi_int + ki_y*-xybodyint(2);
        qd{qn}.theta_int = qd{qn}.theta_int + ki_x*xybodyint(1);
        qd{qn}.th_int = qd{qn}.th_int + ki_z*zbodyint;
        qd{qn}.yaw_int = qd{qn}.yaw_int + ki_yaw*yawint;
        
        %yawint is an angle so we just wrap it;
        qd{qn}.yaw_int = mod(qd{qn}.yaw_int,2*pi);
        qd{qn}.yaw_int = qd{qn}.yaw_int - (qd{qn}.yaw_int>pi)*2*pi;
    end
end