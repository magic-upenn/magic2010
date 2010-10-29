more off;

tUpdate = 0.1;
ids = [1 3];
%ids = [3];

gcsEntrySpread(ids)
mapDisplay('entry');

while 1,
  pause(tUpdate);
  gcsUpdateSpread;
  mapDisplay('update');
end
