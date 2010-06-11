function ret = SetVelocity(v,w)
motorsInit;
global MOTORS


[vCmd wCmd] = VelocityVals2VelocityCmd(v,w);

vcmd.t = GetUnixTime();
vcmd.v = v;
vcmd.w = w;
vcmd.vCmd = vCmd;
vcmd.wCmd = wCmd;

content = MagicVelocityCmdSerializer('serialize',vcmd);
ipcAPIPublishVC(MOTORS.msgName,content);

ret =1;
