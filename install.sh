cd ./scripts
sudo ./installPackages.sh
cd ../
echo MAGIC_DIR=`dirname $0` >> ~/.bashrc
source ~/.bashrc
make