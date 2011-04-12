function gcsPoseFeed()
more off;

global poseFid

if isempty(poseFid),
  poseIP = '64.9.88.210';
  posePort = 6117;

  %  poseFid = tcpopen(poseIP, posePort);
  poseFid = 1;
end

t = gettime;

ids = [];
global RNODE
for id = 1:9,
  if ~isempty(RNODE{id}),
    ids = [ids id];
  end
end

numEntries = length(ids);
sPose = sprintf('%.3f %d', t, numEntries);
for i = 1:length(ids),
  id = ids(i);
  pF1 = RNODE{id}.pF(:,end);
  sP1 = sprintf(' %d 0%d M 1 %.3f %.3f', ...
                i-1, id, pF1(1), pF1(2));
  sPose = [sPose sP1];
end
sPose = [sPose 13];

try
  fprintf(poseFid, sPose);
catch
  disp(sprintf('Error in outputing UGV data'));
end
