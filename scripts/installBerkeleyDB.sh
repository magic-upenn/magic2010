if [ -f db-4.8.30.tar.gz ] || [ -d db-4.8.30 ] || [ -d /opt/db-4.8.30 ]
then :;
else
  wget http://download.oracle.com/berkeley-db/db-4.8.30.tar.gz
fi

if [ -d db-4.8.30 ] || [ -d /opt/db-4.8.30 ]
then :;
else
  echo 'btw I am installing berkeley now'
  tar -xvf db-4.8.30.tar.gz
  sudo mv db-4.8.30 /opt/
  cd /opt/db-4.8.30/build_unix; ../dist/configure --enable-cxx --prefix=/usr/local; make -j 4; sudo make install
  sudo ldconfig
fi

#if using OSX in i368 mode, run the following before configure: export CFLAGS="-arch i386"
