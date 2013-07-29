%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%handleipc

ipcm = deserialize(sipcm(jj).data)

switch ipcm.type
    case 1
        %this is for a single quad
        qn = ipcm.qn;
        seq_cntM(qn) = ipcm.seqcnt;
        seqM(qn).seq = ipcm.seq;
        setitM(qn) = 0;
        seq_timeM(qn) = timer(j);
    case 2
        %this is for updating multiple quad
        qnlist = ipcm.qn;
        for qn=qnlist;
            seq_cntM(qn) = ipcm.seqcnt(qn);
            seqM(qn).seq = ipcm.seq(qn).seq;
            setitM(qn) = 0;
            seq_timeM(qn) = timer(j);
        end
    case 3
        %this is for updating a single quad on multiple processes
        quad = ipcm.qn;
        for qn=1:nquad
            if(ipcid(qn)==quad)
                %qn is the local id, quad is the global
                seq_cntM(qn) = ipcm.seqcnt;
                seqM(qn).seq = ipcm.seq;
                setitM(qn) = 0;
                seq_timeM(qn) = timer(j);
            end
        end
        
    case 4
        %this is for updating multiple quad on multiple processes
        qnlist = ipcm.qn;
        for quad=qnlist
            for(qn=1:nquad)
                if(ipcid(qn)==quad)
                    %qn is the local id, quad is the global
                    seq_cntM(qn) = ipcm.seqcnt(quad);
                    seqM(qn).seq = ipcm.seq(quad).seq;
                    setitM(qn) = 0;
                    seq_timeM(qn) = timer(j);
                end
            end
        end   
end