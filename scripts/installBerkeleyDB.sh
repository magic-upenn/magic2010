if [ -a db-4.8.30.tar.gz ] || [ -a db-4.8.30 ] || [ -a /opt/db-4.8.30 ]
then :;
else
  wget http://download.oracle.com/berkeley-db/db-4.8.30.tar.gz
fi

if [ -a db-4.8.30 ] || [ -a /opt/db-4.8.30 ]
then :;
else
  tar -xvf db-4.8.30.tar.gz
  sudo mv db-4.8.30 /opt/
  cd /opt/db-4.8.30/build_unix; ../dist/configure --enable-cxx --prefix=/usr/local; make -j 4; sudo make install
  sudo ldconfig
fi

#if using OSX in i368 mode, run the following before configure: export CFLAGS="-arch i386"
