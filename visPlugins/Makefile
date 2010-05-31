#check if vis is installed
ifdef VIS_DIR
OBJECTS = VehicleDynamics2D.o $(VIS_DIR)/plugins/so/Lidar2DVisual.so $(VIS_DIR)/plugins/so/Lidar2D.so
TARGETS = MagicLidarScanPublisher.so MagicPlatformSim.so MagicLidarScan2VisLidarData.so MagicPose2VisPose3D.so MagicPlatform.so
endif

include $(MAGIC_DIR)/Makefile.mk
include $(VIS_DIR)/plugins/src/plugins.mk


