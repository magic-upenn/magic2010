%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
if(control_on)
    
    for qn=1:nquad
        ControlLaw
    end
    
    printcnt = printcnt+1;
    for qn=1:nquad
        if(printcnt==printinterval)
            display(sprintf('qd%d seq:%d des:%4.3f, %4.3f, %4.3f act:%4.3f, %4.3f, %4.3f modes:%d,%d',...
                qn,seq_cntM(qn),qd{qn}.pos_des(1),...
                qd{qn}.pos_des(2),qd{qn}.pos_des(3),qd{qn}.pos(1),...
                qd{qn}.pos(2),qd{qn}.pos(3),killflag,qd{qn}.safetymode));
        end
    end
    
    if(printcnt==printinterval)
        printcnt=0;
    end
    
end