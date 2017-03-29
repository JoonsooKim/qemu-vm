TYPE=$1
ARCH=$2

QEMU_DIR=/home/js1304/qemu-vm
MNT_DIR=ubuntu-root-part

if [ "$TYPE" == "" ]; then
	MOUNTED=`mount | grep "$QEMU_DIR/$MNT_DIR" | wc -l`
	if [ "$MOUNTED" == "0" ]; then
		TYPE=mount
	else
		TYPE=unmount
	fi
elif [ "$TYPE" != "mount" ] && [ "$TYPE" != "unmount" ]; then
	echo "Invalid input"
	exit 1;
fi

if [ "$ARCH" == "" ]; then
	ARCH=x86
fi

if [ "$ARCH" == "arm32" ]; then
	echo "Invalid input"
	exit 1;
fi

if [ "$ARCH" == "arm" ]; then
	BIN_DIR=bin-arm32
	IMG=ubuntu-arm32-hf.img

elif [ "$ARCH" == "arm64" ]; then
	BIN_DIR=bin-arm64
	IMG=xenial-server-cloudimg-arm64-disk1.img

elif [ "$ARCH" == "x86" ]; then
	BIN_DIR=bin-x86
	IMG=ubuntu-server-dev.img

elif [ "$ARCH" == "dev" ]; then
	BIN_DIR=bin-dev
	IMG=ubuntu-server-dev.img

elif [ "$ARCH" == "i386" ]; then
	BIN_DIR=bin-i386
	IMG=ubuntu-32-desktop.img

else
	echo "Invalid input"
	exit 1;
fi

echo "TYPE: $TYPE, ARCH: $ARCH, BIN_DIR: $BIN_DIR, IMG: $IMG"

image_mount()
{
	if [ "$TYPE" != "mount" ]; then
		return;
	fi

	if [ "$ARCH" == "arm" ]; then

		sudo mount -t ext4 -o loop $BIN_DIR/$IMG $QEMU_DIR/$MNT_DIR

	elif [ "$ARCH" == "arm64" ]; then

		sudo modprobe nbd max_part=63
		sudo qemu-nbd -c /dev/nbd0 $BIN_DIR/$IMG
		sudo mount /dev/nbd0p1 $QEMU_DIR/$MNT_DIR

	elif [ "$ARCH" == "x86" ]; then

		sudo kpartx -a $BIN_DIR/$IMG
		sudo vgchange -a y
		sudo mount /dev/ubuntu-vg/root $QEMU_DIR/$MNT_DIR

	elif [ "$ARCH" == "dev" ]; then

		sudo kpartx -a $BIN_DIR/$IMG
		sudo vgchange -a y
		sudo mount /dev/ubuntu-vg/root $QEMU_DIR/$MNT_DIR

	elif [ "$ARCH" == "i386" ]; then

		sudo kpartx -a $BIN_DIR/$IMG
		sudo mount /dev/mapper/loop0p1 $QEMU_DIR/$MNT_DIR

	else
		echo "Invalid input"
		exit 1;
	fi

	echo "Mount $BIN_DIR/$IMG on $QEMU_DIR/$MNT_DIR"
}

image_unmount()
{
	if [ "$TYPE" != "unmount" ]; then
		return;
	fi

	sudo umount $QEMU_DIR/$MNT_DIR

	if [ "$ARCH" == "arm" ]; then
		echo "" > /dev/null

	elif [ "$ARCH" == "arm64" ]; then

		sudo qemu-nbd -d /dev/nbd0

	elif [ "$ARCH" == "x86" ]; then

		sudo vgchange -a n
		sudo kpartx -d $BIN_DIR/$IMG

	elif [ "$ARCH" == "dev" ]; then

		sudo vgchange -a n
		sudo kpartx -d $BIN_DIR/$IMG

	elif [ "$ARCH" == "i386" ]; then

		sudo kpartx -d $BIN_DIR/$IMG

	else
		echo "Invalid input"
		exit 1;
	fi

	echo "Unmount $BIN_DIR/$IMG on $QEMU_DIR/$MNT_DIR"
}

image_mount;
image_unmount;
