function msg = uavParse(fid);
% msg = uavParse(fid);
% UAV data parser for MAGIC 2010 competition.

msg = [];
tline = fgets(fid);

try
  [C, pos] = textscan(tline, '%f %n', 1);
  time = C{1};
  numEntries = C{2};

  C = textscan(tline(pos:end), '%n %s %c %n %f %f', numEntries);
catch
  error(lasterror);
end

disp(sprintf('%3f %d ', time, numEntries));
if (length(C{1}) ~= numEntries), return, end;

for i = 1:numEntries,
  point(i).id = C{1}(i);
  point(i).hex_id = 0;%hex2dec(C{2}{i});
  point(i).type = C{3}(i);
  point(i).updated = C{4}(i);
  point(i).easting = C{5}(i);
  point(i).northing = C{6}(i);

  disp(sprintf('[ %d(%d) %c (%.3f %.3f)] ', ...
               point(i).id, point(i).hex_id, point(i).type, ...
               point(i).easting, point(i).northing));
end

msg.time = time;
msg.numEntries = numEntries;
msg.point = point;
