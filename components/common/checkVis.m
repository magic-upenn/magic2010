function ret = checkVis()
global USE_VIS

if isempty(USE_VIS)
  visDir = getenv('VIS_DIR');
  if isempty(visDir)
    ret =0;
  else
    ret =1;
  end
else
  ret = USE_VIS;
end