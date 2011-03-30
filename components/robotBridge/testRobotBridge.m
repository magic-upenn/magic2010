SetMagicPaths;

ipcAPIConnect('localhost:1382');

req.name = GetMsgName('Lidar0');

ipcAPIPublish(GetMsgName('SubscriptionRequest'),serialize(req));