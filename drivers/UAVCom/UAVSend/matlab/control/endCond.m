%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%multi control decide if sequence has ended

if(timer(j)>(seq_timeM(qn)+seqM(qn).seq(seq_cntM(qn)).time))
    %if the time has exceeded the specified time then switch to the next
    %sequence
    
    seq_timeM(qn) = seq_timeM(qn) + seqM(qn).seq(seq_cntM(qn)).time;
    seq_cntM(qn) = seq_cntM(qn) + 1;
    setitM(qn) = 0;
    
elseif(~isempty(seqM(qn).seq(seq_cntM(qn)).unixtime))
    
    if(timer(j)+time0>seqM(qn).seq(seq_cntM(qn)).unixtime)
        %if the time has exceeded the specified unixtime then switch
        
        seq_timeM(qn) = seqM(qn).seq(seq_cntM(qn)).unixtime - time0;
        seq_cntM(qn) = seq_cntM(qn) + 1;
        setitM(qn) = 0;
        
    end
end