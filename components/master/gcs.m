more off;

tUpdate = 0.1;
%ids = [1 3];
ids = [3];

gcsEntry(ids)
mapDisplay('entry');

while 1,
  pause(tUpdate);
  gcsUpdate;
  mapDisplay('update');
end
