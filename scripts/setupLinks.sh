#shell script to setup hardware specific links

ARCH=$(uname -m)
if ["$ARCH" = "x86_64"]
then
    SUFFIX=64
else
    SUFFIX=32
fi

sudo rm /usr/local/include/ipc.h
sudo rm /usr/local/lib/libipc.a
sudo rm /usr/local/bin/central
sudo rm /usr/local/bin/xdrgen

sudo ln -s $MAGIC_DIR/ipc/ipc.h /usr/local/include/ipc.h
sudo ln -s $MAGIC_DIR/ipc/libipc.a.linux$SUFFIX /usr/local/lib/libipc.a
sudo ln -s $MAGIC_DIR/ipc/central.linux$SUFFIX /usr/local/bin/central
sudo ln -s $MAGIC_DIR/ipc/xdrgen.linux$SUFFIX /usr/local/bin/xdrgen

sudo chmod 755 /usr/local/bin/central
sudo chmod 755 /usr/local/bin/xdrgen
sudo chmod 4755 /usr/bin/nice
sudo chmod 4755 /usr/bin/renice

sudo ln -s /usr/bin/ccache /usr/local/bin/gcc
sudo ln -s /usr/bin/ccache /usr/local/bin/g++
sudo ln -s /usr/bin/ccache /usr/local/bin/cc
