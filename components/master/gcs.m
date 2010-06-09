more off;

tUpdate = 0.1;
%ids = [1 3];
%ids = [3];
ids = [2];

gcsEntryIPC(ids)
mapDisplay('entry');

while 1,
  pause(tUpdate);
  gcsUpdateIPC;
  mapDisplay('update');
end
