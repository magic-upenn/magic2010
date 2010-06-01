function ret = SetVelocity(v,w)
motorsInit;
global MOTORS


[vCmd wCmd] = VelocityVals2VelocityCmd(v,w);

MOTORS.vcmd.t = GetUnixTime();
MOTORS.vcmd.v = v;
MOTORS.vcmd.w = w;
MOTORS.vcmd.vCmd = vCmd;
MOTORS.vcmd.wCmd = wCmd;

content = MagicVelocityCmdSerializer('serialize',MOTORS.vcmd);
ipcAPIPublishVC(MOTORS.msgName,content);

ret =1;
