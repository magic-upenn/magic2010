%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%LimitForce

if(qd{qn}.type==1)
    %type is nano
    Force = min(max(Force,9.81*0.003),9.81*0.135);
elseif(qd{qn}.type==2)
    %type is kilo
    Force = min(max(Force,9.81*0.003),9.81*2.0);
elseif(qd{qn}.type==3)
    %type is kilo
    Force = min(max(Force,9.81*0.003),9.81*1.0);
elseif(qd{qn}.type==5)
    %type is deka
    Force = min(max(Force,9.81*0.003),9.81*1.6);
elseif(qd{qn}.type==6)
    %type is Mega
    Force = min(max(Force,9.81*0.003),9.81*4.7);
elseif(qd{qn}.type==7)
    %type is new nano
    Force = min(max(Force,9.81*0.003),9.81*0.3);
else
    Force = 0;
end