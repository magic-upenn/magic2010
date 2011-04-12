function sendServoCmd(id)

global ROBOTS HAVE_ROBOTS GDISPLAY

msgName = ['Robot',num2str(id),'/Use_Servo'];

if HAVE_ROBOTS,
  try
    ROBOTS(id).ipcAPI('publish', msgName, serialize(get(GDISPLAY.robotServoControl{id},'Value')));
  catch
  end
end
