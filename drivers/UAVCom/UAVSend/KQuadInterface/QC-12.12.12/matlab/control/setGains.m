%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%set the gains for the controller
kp_x = seqM(qn).seq(seq_cntM(qn)).kp_x;
kd_x = seqM(qn).seq(seq_cntM(qn)).kd_x;
ki_x = seqM(qn).seq(seq_cntM(qn)).ki_x;

kp_y = seqM(qn).seq(seq_cntM(qn)).kp_y;
kd_y = seqM(qn).seq(seq_cntM(qn)).kd_y;
ki_y = seqM(qn).seq(seq_cntM(qn)).ki_y;

kp_z = seqM(qn).seq(seq_cntM(qn)).kp_z;
kd_z = seqM(qn).seq(seq_cntM(qn)).kd_z;
ki_z = seqM(qn).seq(seq_cntM(qn)).ki_z;

if(~isempty(seqM(qn).seq(seq_cntM(qn)).ki_yaw))
    ki_yaw = seqM(qn).seq(seq_cntM(qn)).ki_yaw;
else
    ki_yaw = 0;
end