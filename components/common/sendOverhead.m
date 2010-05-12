addpath( [ getenv('VIS_DIR') '/ipc' ] )

host = 'localhost';
ipcAPIConnect(host);
imgMsgName = ['screen' VisMarshall('getMsgSuffix','ImageData')];
imgMsgFormat  = VisMarshall('getMsgFormat','ImageData');
ipcAPIDefine(imgMsgName,imgMsgFormat);


im=imread('~/svn/magic2010/trunk/components/slam/upenn_small.jpg');
im=im(100:4000,5000:10125,:);

width=size(im,2);
height=size(im,1);

while(1)
  content = VisMarshall('marshall','ImageData',im);
  ipcAPIPublishVC(imgMsgName,content);
  
  return;
  pause(0.1);
end


  
  