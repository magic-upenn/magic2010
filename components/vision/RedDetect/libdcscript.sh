#!/bin/bash
sudo modprobe ohci1394
sudo modprobe video1394
sudo modprobe ieee1394
sudo modprobe raw1394
cd /dev
sudo mknod raw1394 c 171 0
sudo chmod 666 /dev/raw1394
sudo mkdir video1394
sudo chmod 777 video1394
cd video1394
sudo mknod 0 c 171 16
sudo mknod 1 c 171 17
sudo chmod 666 /dev/video1394/*
