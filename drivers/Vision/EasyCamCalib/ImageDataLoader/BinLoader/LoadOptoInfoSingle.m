function [OptoR OptoT] = LoadOptoInfoSingle(imagepath, objnum_optofile, arthroscope_obj)

OptoR = [];
OptoT = [];
s = imagepath;
[p, name, ext] = fileparts(s);

if exist(sprintf('%s/OptoTracker.txt',p),'file')==2
    n = name(end-2:end);
    [OptoR OptoT]  = LoadOptoTrackMotion(sprintf('%s/OptoTracker.txt',p) ,objnum_optofile , arthroscope_obj, sprintf('%s%s',n,ext));
    if isempty(OptoR) || isempty (OptoT)
        disp(sprintf('WARNING: No valid optotracker for image %s',s))
    end
else
    display('WARNING!!! No OptoTracker file found');
end