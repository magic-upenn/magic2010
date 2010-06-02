function id = GetIdFromName(name)

if nargin < 1 || ~ischar(name)
  error('please provide a string argument');
end

iStart = 6;
iEnd   = iStart;
while name(iEnd+1) ~= '/'
  iEnd=iEnd+1;
end

id = str2double(name(iStart:iEnd));

if isnan(id)
  error('could not get id from name : %s',name);
end
