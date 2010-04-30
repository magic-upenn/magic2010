function omapSubscribe
global OMAP

omapInit;
ipcAPISubscribe(OMAP.msgName);