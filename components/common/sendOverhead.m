addpath( [ getenv('VIS_DIR') '/ipc' ] )

host = 'localhost';
ipcAPIConnect(host);
imgMsgName = ['overhead' VisMarshall('getMsgSuffix','ImageData')];
imgMsgFormat  = VisMarshall('getMsgFormat','ImageData');
ipcAPIDefine(imgMsgName,imgMsgFormat);


im=imread([getenv('MAGIC_DIR') '/components/slam/SiteVisitOverhead.jpg']);

width=size(im,2);
height=size(im,1);

while(1)
  content = VisMarshall('marshall','ImageData',im);
  ipcAPIPublishVC(imgMsgName,content);
  
  return;
  pause(0.1);
end


  
  
