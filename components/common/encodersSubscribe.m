function encodersSubscribe
global ENCODERS

encodersInit;
ipcAPISubscribe(ENCODERS.msgName);