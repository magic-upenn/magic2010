%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%send the Command to the vehicle

% if(~sim_on)
%     if(qd{qn}.safetymode==0 & killflag==0)
%         %normal operation
%         qd{qn}.driver('setTrpyDG',qd{qn}.kbeeid,qd{qn}.kbeechannel,trpy,drpy,qd{qn}.onboardkp,qd{qn}.onboardkd);
%     elseif(qd{qn}.safetymode==1 & killflag==0)
%         %safety descent
%         trpy = [seqM(qn).seq(seq_cntM(qn)).safety_thrust,qd{qn}.phi_int,qd{qn}.theta_int,qd{qn}.yawcmdsafety];
%         qd{qn}.driver('setTrpyDG',qd{qn}.kbeeid,qd{qn}.kbeechannel,trpy,drpy,qd{qn}.onboardkp,qd{qn}.onboardkd);
%     else
%         %kill props
%         trpy = [0,0,0,0];
%         qd{qn}.driver('setTrpyDG',qd{qn}.kbeeid,qd{qn}.kbeechannel,[0,0,0,0],[0,0,0],qd{qn}.onboardkp,qd{qn}.onboardkd);
%     end
% end

%KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);

if(qd{qn}.type == 1 | qd{qn}.type == 7)
    cmdtype = 1; %0 for standard, 1 for nano
else
    cmdtype = 0;
end

if(~sim_on)
    if(quadcmdtype==1)
        if(qd{qn}.safetymode==0 & killflag==0)
            %normal operation
            qd{qn}.driver('SendQuadCmd1',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,trpy);
        elseif(qd{qn}.safetymode==1 & killflag==0)
            %safety descent
            trpy = [seqM(qn).seq(seq_cntM(qn)).safety_thrust,qd{qn}.phi_int,qd{qn}.theta_int,qd{qn}.yawcmdsafety];
            qd{qn}.driver('SendQuadCmd1',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,trpy);
        else
            %kill props
            trpy = [0,0,0,0];
            qd{qn}.driver('SendQuadCmd1',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,[0,0,0,0]);
        end
    elseif(quadcmdtype==3)
        if(qd{qn}.safetymode==0 & killflag==0)
            %normal operation
            qd{qn}.driver('SendQuadCmd3',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,trpy,drpy,qd{qn}.onboardkp,qd{qn}.onboardkd);
        elseif(qd{qn}.safetymode==1 & killflag==0)
            %safety descent
            trpy = [seqM(qn).seq(seq_cntM(qn)).safety_thrust,qd{qn}.phi_int,qd{qn}.theta_int,qd{qn}.yawcmdsafety];
            qd{qn}.driver('SendQuadCmd3',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,trpy,drpy,qd{qn}.onboardkp,qd{qn}.onboardkd);
        else
            %kill props
            trpy = [0,0,0,0];
            qd{qn}.driver('SendQuadCmd3',qd{qn}.kbeeid,qd{qn}.kbeechannel,cmdtype,[0,0,0,0],[0,0,0],qd{qn}.onboardkp,qd{qn}.onboardkd);
        end
    end
end

%log the data
trpySave(:,j,c) = trpy';
intSave(:,j,c) = [qd{qn}.th_int,qd{qn}.phi_int,qd{qn}.theta_int,qd{qn}.yaw_int]';
DesEulSave(3,j,qn) = qd{qn}.euler_des(3);