make clean
cd /opt/db-4.8.30/build_unix
sudo make uninstall
cd $MAGIC_DIR
sudo rm -rf /opt/db-4.8.30
sudo rm -rf scripts/db-4.8.30
sudo rm -f scripts/db-4.8.30.tar.gz

sudo apt-get remove openssh-server build-essential libxml2-dev ccache avrdude gcc-avr avr-libc guvcview xvnc4viewer gmountiso
sudo apt-get autoremove
