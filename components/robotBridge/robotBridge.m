function robotBridge()
SetMagicPaths;



ipcAPIBridgeInternalConnect();
ipcAPIBridgeExternalConnect();

subsReqMsgName = GetMsgName('SubscriptionRequest');

ipcAPIBridgeExternalDefine(subsReqMsgName);
ipcAPIBridgeExternalSubscribe(subsReqMsgName,5);


RobotBridgeInitMessages();

while(1)
  
  ReceiveExternalMessages();
  
  ReceiveInternalMessages();
  
  
  fprintf('.');
  pause(0.05);
  %usleep(10000);
end

function ReceiveExternalMessages()
msgs = ipcAPIBridgeExternalListen(0);
len  = length(msgs);

for ii=1:len
  msg = msgs(ii);
  msgName = msg.name;

  switch (msgName)
    case subsReqMsgName
      ProcessSubscriptionRequest(msg);
  end

end

function ReceiveInternalMessages()
msgs = ipcAPIBridgeInternalListen(0);
len  = length(msgs);

for ii=1:len
  msg = msgs(ii);
  msgName = msg.name;

  ipcAPIBridgeExternalPublish

end




function ProcessSubscriptionRequest(msg)
req = deserialize(msg.data);

if ~isfield(req,'name')
  fprintf('bad request');
end

ipcAPIBridgeInternalSubscribe(req.name,5);
fprintf('subscribed to internal message %s\n',req.name);

