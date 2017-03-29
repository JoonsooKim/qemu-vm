KERNEL_GIT_DIR=/home/js1304/Projects/remote_git/linux
QEMU_DIR=/home/js1304/qemu-vm
MNT_DIR=ubuntu-root-part

cd $KERNEL_GIT_DIR
if [ "$ARCH" == "" ]; then
	sudo INSTALL_MOD_PATH=$QEMU_DIR/$MNT_DIR make modules_install
else
	sudo ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=$QEMU_DIR/$MNT_DIR make modules_install
fi
