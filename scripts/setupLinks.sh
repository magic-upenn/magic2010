sudo ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab
sudo ln -s /opt/matlab/bin/mex /usr/local/bin/mex
sudo ln -s /opt/matlab/bin/mexext /usr/local/bin/mexext

sudo ln -s $MAGIC_DIR/ipc/ipc.h /usr/local/include/ipc.h
sudo ln -s $MAGIC_DIR/ipc/libipc.a.linux32 /usr/local/lib/libipc.a
sudo ln -s $MAGIC_DIR/ipc/central.linux32 /usr/local/bin/central
sudo ln -s $MAGIC_DIR/ipc/xdrgen.linux32 /usr/local/bin/xdrgen

sudo chmod 755 /usr/local/bin/central
sudo chmod 755 /usr/local/bin/xdrgen
sudo chmod 4755 /usr/bin/nice

sudo ln -s /usr/bin/ccache /usr/local/bin/gcc
sudo ln -s /usr/bin/ccache /usr/local/bin/g++
sudo ln -s /usr/bin/ccache /usr/local/bin/cc


