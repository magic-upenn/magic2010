function ret = SetVelocity(v,w)
motorsInit;
global MOTORS

MOTORS.vcmd.t = GetUnixTime();
MOTORS.vcmd.v = v*MOTORS.vscale;
MOTORS.vcmd.w = w*MOTORS.wscale;

content = MagicVelocityCmdSerializer('serialize',MOTORS.vcmd);
ipcAPIPublishVC(MOTORS.msgName,content);

ret =1;
