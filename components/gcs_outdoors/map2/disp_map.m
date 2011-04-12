global RNODE

iRobot = [];
for id = 1:9,
  if ~isempty(RNODE{id}),
    iRobot = [iRobot id];
  end
end

gdispInit;

n = 0;
loop = true;
while loop,
  n = n+1;
  loop = false;
  for id = iRobot,
    pF = RNODE{id}.pF;
    if (size(pF,2) >= n),
      loop = true;
      gdispRobot(id, pF(:,n));
    end
  end
  drawnow
end