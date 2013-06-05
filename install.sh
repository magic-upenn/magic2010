cd ./scripts
sudo ./installPackages.sh
cd ../
echo MAGIC_DIR=`dirname $0` >> ~/.bashrc
echo ROBOT_ID=1 >> ~/.bashrc
echo IPC_CENTRAL_INTERNAL=localhost:1381
export IPC_CENTRAL_EXTERNAL=localhost:1382

source ~/.bashrc
make