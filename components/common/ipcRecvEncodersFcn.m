function ipcRecvEncodersFcn(msg)

global ENCODERS

if ~isempty(msg)
  ENCODERS.counts  = MagicEncoderCountsSerializer('deserialize',msg);
      
  if isempty(ENCODERS.tLastReset)
    ENCODERS.tLastReset = ENCODERS.counts.t;
  end
  
  counts = ENCODERS.counts;
  ENCODERS.acounts = ENCODERS.acounts + [counts.fr;counts.fl;counts.rr;counts.rl];


  dt = counts.t-ENCODERS.tLastReset;
  if (dt > 0.1)
    ENCODERS.wheelVels = ENCODERS.acounts / dt * ENCODERS.metersPerTic;
    ENCODERS.acounts = ENCODERS.acounts*0;
    ENCODERS.tLastReset = counts.t;
  end
end