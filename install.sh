cd ./scripts
sudo ./installPackages.sh
cd ../

cat >magicvars.sh <<EOT
export PATH=/usr/local/MATLAB/R2012b/bin:$PATH
export MAGIC_DIR=`pwd`
export LD_LIBRARY_PATH=/usr/local/lib
export LIDAR0_SERIAL=00907260
export LIDAR1_SERIAL=00908820 
export MASTER_IP=158.130.111.167
export ROBOT_ID=8
export IPC_CENTRAL_INTERNAL=localhost:1381
export IPC_CENTRAL_EXTERNAL=localhost:1382
EOT
chmod +x magicvars.sh

if grep -q magicvars.sh ~/.bashrc
then
	echo "bashrc already sources magicvars"
else
	echo "adding magicvars to bashrc"
	echo "source `pwd`/magicvars.sh" >>~/.bashrc
fi


source ~/.bashrc
make
./scripts/setupLinks.sh

