sudo ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab
sudo ln -s /opt/matlab/bin/mex /usr/local/bin/mex
sudo ln -s /opt/matlab/bin/mexext /usr/local/bin/mexext

sudo rm /usr/local/include/ipc.h
sudo rm /usr/local/lib/libipc.a
sudo rm /usr/local/bin/central
sudo rm /usr/local/bin/xdrgen

sudo ln -s $MAGIC_DIR/ipc/ipc.h /usr/local/include/ipc.h
sudo ln -s $MAGIC_DIR/ipc/libipc.a.linux64 /usr/local/lib/libipc.a
sudo ln -s $MAGIC_DIR/ipc/central.linux64 /usr/local/bin/central
sudo ln -s $MAGIC_DIR/ipc/xdrgen.linux64 /usr/local/bin/xdrgen

sudo chmod 755 /usr/local/bin/central
sudo chmod 755 /usr/local/bin/xdrgen
sudo chmod 4755 /usr/bin/nice
sudo chmod 4755 /usr/bin/renice

sudo ln -s /usr/bin/ccache /usr/local/bin/gcc
sudo ln -s /usr/bin/ccache /usr/local/bin/g++
sudo ln -s /usr/bin/ccache /usr/local/bin/cc


