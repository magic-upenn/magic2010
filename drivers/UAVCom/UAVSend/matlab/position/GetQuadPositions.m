%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.

if(sim_on)
    for qn=1:nquad
        qd{qn}.pos = qd{qn}.pos_des;
        qd{c}.vel = qd{c}.vel_des;
    end
    pause(1/100);
else
    if(vicon_on)
        viconUpdate4;
    else
        pause(1/100);
    end
end