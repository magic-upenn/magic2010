function ret = SetVelocity(v,w)
motorsInit;
global MOTORS


[vCmd wCmd] = VelocityVals2VelocityCmd(v,w);

MOTORS.vcmd.t = GetUnixTime();
MOTORS.vcmd.v = vCmd;
MOTORS.vcmd.w = wCmd;

content = MagicVelocityCmdSerializer('serialize',MOTORS.vcmd);
ipcAPIPublishVC(MOTORS.msgName,content);

ret =1;
