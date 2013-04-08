#check if vis is installed
ifdef VIS_DIR
OBJECTS = VehicleDynamics2D.o $(VIS_DIR)/plugins/so/Lidar2DVisual.so $(VIS_DIR)/plugins/so/Lidar2D.so Servo1DSim.o
TARGETS = MagicLidarScanPublisher.so MagicPlatformSim.so MagicLidarScan2VisLidarData.so MagicPose2VisPose3D.so MagicPlatform.so MagicServoSim.so MagicServoState2VisPose.so

include $(VIS_DIR)/plugins/src/plugins.mk
#overwrite the libraries
LIBS = -lvis -lipc


endif

include $(MAGIC_DIR)/Makefile.mk


