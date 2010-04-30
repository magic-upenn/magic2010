function emapSubscribe
global EMAP

emapInit;
ipcAPISubscribe(EMAP.msgName);