%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%decide if it is time to switch sequences
endCond

%compute the control based on the current mode
if(seqM(qn).seq(seq_cntM(qn)).type==700)
    directMode
else
    setGains
    
    if(seqM(qn).seq(seq_cntM(qn)).type==55)
        waypointMode
    elseif(seqM(qn).seq(seq_cntM(qn)).type==755)
        takeoffMode
    elseif(seqM(qn).seq(seq_cntM(qn)).type==7)
        hoverMode
    end
    
    positionControl
end

%apply the safety logic
safetyLogic

%send out the command
sendCmd