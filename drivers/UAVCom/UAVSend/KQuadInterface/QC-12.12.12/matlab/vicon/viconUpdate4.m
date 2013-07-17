%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%June 29, 2012
%Update the position of each vehicle with vicon

%try to read the data from vicon 10 times and pause 1 ms after each attempt
checkviconcnt = 0;
vdata = [];
while(checkviconcnt<10)
    vdata = ViconAPI2('get_data',0);
    
    if(isempty(vdata))
        %vdata was not received so pause 1ms and try again
        usleep(1000);
        checkviconcnt = checkviconcnt +1;
    else
        %vdata was received so exit the loop
        checkviconcnt = 100;
    end
end

if(~isempty(vdata)) 
    for c=1:nquad
        if(~isempty(qd{c}.viconid))
            %find the body and world frame marker positions
            [BodyGood,World] = matchQuadrotor2(qd{c}.id,vdata(end),qd{c}.viconid);
            
            if(~isempty(BodyGood))
                
                delT = (vdata(end).frameCntr - qd{c}.framelast)/viconrate;
                
                %filter parameters for estimation
                alfa_vel = (delT/(estimation.tau_vel+delT));  
                alfa_pos = (delT/(estimation.tau_pos+delT));
                
                %find the least squares rotation and translation
                [W_R_QuadBV,W_T_QuadBV] = PointsToRot(BodyGood,World);
                
                %the rotation matrix of the body frame
                W_R_QuadB = W_R_QuadBV * qd{c}.QuadB_R_QuadBVM';
                
                %compute the euler angles
                [euler(1,1),euler(2,1),euler(3,1)] = RotToRPY_ZXY(W_R_QuadB');
                euler = euler - (euler>pi)*2*pi;
                
                %%position vector from world origin to body origin
                newpos = (W_T_QuadBV - W_R_QuadBV*qd{c}.T_rel_BVM)/1000; 
                
                %estimate the velocity
                posdiff = newpos - qd{c}.pos_raw;
                vel_estnew = (posdiff)/delT;
                
                %only allow a maximum velocity
                for jj=1:3
                    vel_estnew(jj) = max(min(vel_estnew(jj),estimation.maxvel),-estimation.maxvel);
                end
                
                %check that the two rotation matrices are close
                Rotdiff = W_R_QuadB'*qd{c}.Rot_last;
                costhetadiff = (trace(Rotdiff)-1)/2;
                
                if(j>200 & (sqrt(sum(posdiff.^2))>0.3 | newpos(1)<safety.safebox(1) | ...
                        newpos(1)>safety.safebox(2) |...
                        newpos(2)<safety.safebox(3) | newpos(2)>safety.safebox(4) | ...
                        newpos(3)<safety.safebox(5) | newpos(3)>safety.safebox(6) | ...
                        abs(euler(1))>pi/2 | abs(euler(2))>pi/2 | costhetadiff<0.8660))
                    %this means there is a problem
                else
                    %we are ok so update the vicondata
                    qd{c}.vtime = GetUnixTime;
                    qd{c}.framelast = vdata(end).frameCntr;
                    qd{c}.Rot_last = W_R_QuadB;
                    qd{c}.euler = euler;
                    qd{c}.vel = alfa_vel*vel_estnew + (1-alfa_vel)*qd{c}.vel;
                    qd{c}.pos_raw = newpos;
                    
                    qd{c}.pos = alfa_pos*newpos + (1-alfa_pos)*(qd{c}.pos);
                end
            end
        end
    end
end

%log the data
for c=1:nquad
    VelSave(:,j,c)=[qd{c}.vel];
    ViconData(:,j,c) = [qd{c}.euler;qd{c}.pos];
end