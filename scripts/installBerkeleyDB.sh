if [ -a db-4.8.30.tar.gz ] || [ -a db-4.8.30 ] || [ -a /opt/db-4.8.30 ]
then :;
else
  wget https://uav-planning.no-ip.org/MagicSoftware/db-4.8.30.tar.gz --no-check-certificate
fi

if [ -a db-4.8.30 ] || [ -a /opt/db-4.8.30 ]
then :;
else
  tar -xvf db-4.8.30.tar.gz
  sudo mv db-4.8.30 /opt/
  cd /opt/db-4.8.30/build_unix; ../dist/configure --enable-cxx --prefix=/usr/local; make -j 4; sudo make install
  sudo ldconfig
fi
