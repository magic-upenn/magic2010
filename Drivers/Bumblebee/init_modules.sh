sudo modprobe ohci1394
sudo modprobe ieee1394
sudo modprobe video1394
sudo modprobe raw1394

sudo chmod 777 /dev/video1394/*
sudo chmod 777 /dev/raw1394


