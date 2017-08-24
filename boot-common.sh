ARCH=$1
TYPE=$2
MEM=$3
KERNEL_EXTRA_PARAM=$4


#QEMU_DEBUG_PARAM="-serial stdio -monitor none"
#QEMU_DEBUG_PARAM="-monitor telnet:127.0.0.1:1234,server,nowait"
#MEM="6G,slots=4,maxmem=8G -numa node,mem=5G -numa node,mem=1G"
DEBUG=1
GDB=0

SMP=4
REMOTE_DEV_HOST=localhost
REMOTE_DEV_HOST_PORT=9999

KERNEL_GIT_DIR=/home/js1304/Projects/remote_git/linux
QEMU_DIR=/home/js1304/qemu-vm

if [ "$ARCH" == "arm32" ]; then
	BIN_DIR=bin-arm32
	KERNEL_BIN_DIR=arch/arm/boot
	KERNEL_BIN=zImage

	KERNEL_DEFAULT_BIN=$BIN_DIR/vmlinuz-3.13.0-24-generic

	INITRD=initrd.img-3.13.0-24-generic
	QEMU_INITRD="-initrd $BIN_DIR/$INITRD"

	IMG=ubuntu-arm32-hf.img
	QEMU_IMG="-sd $BIN_DIR/$IMG"

	KERNEL_ROOT_PARAM="rootwait root=/dev/mmcblk0 init=/sbin/init"
	KERNEL_DEFAULT_PARAM="console=ttyAMA0 rw raid=noautodetect devtmpfs.mount=0 ignore_loglevel"

	SSH_REDIR_PORT=5555

	QEMU_CMD="./qemu-system-arm -machine vexpress-a9"
	QEMU_NET="-net nic,model=lan9118 -net user,hostfwd=tcp::$SSH_REDIR_PORT-:22"
	QEMU_EXTRA_PARAM="-dtb $BIN_DIR/vexpress-v2p-ca9.dtb"

elif [ "$ARCH" == "arm64" ]; then
	BIN_DIR=bin-arm64
	KERNEL_BIN_DIR=arch/arm64/boot
	KERNEL_BIN=Image.gz

	KERNEL_DEFAULT_BIN=$BIN_DIR/vmlinuz-4.4.0-31-generic

	INITRD=initrd.img-4.4.0-31-generic
	QEMU_INITRD="-initrd $BIN_DIR/$INITRD"

	IMG=xenial-server-cloudimg-arm64-disk1.img
	CLOUD_IMG=cloud.img
	QEMU_IMG=" \
		-global virtio-blk-device.scsi=off -device virtio-scsi-device,id=scsi \
		-drive file=$BIN_DIR/$IMG,format=qcow2,id=coreimg,cache=unsafe,if=none -device scsi-hd,drive=coreimg \
		-device virtio-blk-device,drive=cloud \
		-drive if=none,id=cloud,file=$BIN_DIR/$CLOUD_IMG \
		"

	KERNEL_ROOT_PARAM="root=/dev/sda1"
	KERNEL_DEFAULT_PARAM="console=ttyAMA0 ds=nocloud earlycon=pl011,0x9000000"

	SSH_REDIR_PORT=5555

	QEMU_CMD="./qemu-system-aarch64 -machine virt -cpu cortex-a57 -machine type=virt"
	QEMU_NET="-netdev user,id=unet -device virtio-net-device,netdev=unet \
		-redir tcp:$SSH_REDIR_PORT::22"

elif [ "$ARCH" == "x86" ]; then
	SMP=8
	KERNEL_DEFAULT_BIN=""

	BIN_DIR=bin-x86

	KERNEL_BIN_DIR=arch/x86/boot
	KERNEL_BIN=bzImage

	INITRD=initrd.img-4.4.0-45-generic
	QEMU_INITRD="-initrd $BIN_DIR/$INITRD"

	IMG="ubuntu-server-dev.img"
	QEMU_IMG="-drive file=$BIN_DIR/$IMG,if=virtio,cache=none"
#	echo "WARNING!!!!!!: disk setup is changed to the disk on HDD rather than SSD"
#	QEMU_IMG="-drive file=/home/js1304/HDD/qemu-vm/bin-x86/$IMG,if=virtio,cache=none"
	QEMU_IMG="$QEMU_IMG -hdd /home/js1304/HDD/qemu-vm/tmp-disk.img"

	KERNEL_ROOT_PARAM="root=/dev/mapper/ubuntu--vg-root"
	KERNEL_DEFAULT_PARAM="console=ttyS0 ro ignore_loglevel"

	SSH_REDIR_PORT=5555

	QEMU_CMD="./qemu-system-x86_64-recent -enable-kvm -cpu host"
	QEMU_NET="-redir tcp:$SSH_REDIR_PORT::22"

elif [ "$ARCH" == "dev" ]; then
	SMP=8
	MEM=4096
	TYPE=default
	KERNEL_DEFAULT_BIN=""
	GDB=0

	BIN_DIR=bin-dev

	IMG=ubuntu-server-dev.img
	QEMU_IMG="-drive file=$BIN_DIR/$IMG,if=virtio,cache=none"

	KERNEL_ROOT_PARAM="root=/dev/mapper/ubuntu--vg-root"
	KERNEL_DEFAULT_PARAM="console=ttyS0 ro ignore_loglevel"

	SSH_REDIR_PORT=9999

	QEMU_CMD="./qemu-system-x86_64-recent -enable-kvm -cpu host"
	QEMU_NET="-redir tcp:$SSH_REDIR_PORT::22"

elif [ "$ARCH" == "i386" ]; then
	SMP=8
	MEM=4096
	KERNEL_DEFAULT_BIN=""

	BIN_DIR=bin-i386

	KERNEL_BIN_DIR=arch/x86/boot
	KERNEL_BIN=bzImage

	INITRD=initrd.img-4.2.0-27-generic
	QEMU_INITRD="-initrd $BIN_DIR/$INITRD"

	IMG=ubuntu-32-desktop.img
	QEMU_IMG="-drive file=$BIN_DIR/$IMG,if=virtio,cache=none"

	KERNEL_ROOT_PARAM="root=/dev/vda1"
	KERNEL_DEFAULT_PARAM="console=ttyS0 ro ignore_loglevel"

	SSH_REDIR_PORT=5555

	QEMU_CMD="./qemu-system-i386-recent -enable-kvm -cpu host"
	QEMU_NET="-redir tcp:$SSH_REDIR_PORT::22"

else
	echo "Invalid input"
	exit 1;
fi

if [ "$TYPE" == "" ] || [ "$TYPE" == "local" ]; then
        KERNEL=$KERNEL_GIT_DIR/$KERNEL_BIN_DIR/$KERNEL_BIN
elif [ "$TYPE" == "remote" ]; then
	scp -P $REMOTE_DEV_HOST_PORT $REMOTE_DEV_HOST:$KERNEL_GIT_DIR/$KERNEL_BIN_DIR/$KERNEL_BIN $BIN_DIR/$KERNEL_BIN
	KERNEL=$BIN_DIR/$KERNEL_BIN
elif [ "$TYPE" == "default" ]; then
	KERNEL=$KERNEL_DEFAULT_BIN
else
	KERNEL=$QEMU_DIR/bin-kernel/$TYPE
fi

if [ "$DEBUG" == "1" ]; then
	KERNEL_DEBUG_PARAM="debug earlyprintk"
	QEMU_DEBUG_PARAM="-serial stdio -monitor none"
	if [ "$GDB" == "1" ]; then
		QEMU_DEBUG_PARAM="$QEMU_DEBUG_PARAM -s"
	fi
fi

#KERNEL_EXTRA_PARAM=""
KERNEL_PARAM="$KERNEL_ROOT_PARAM $KERNEL_DEFAULT_PARAM $KERNEL_DEBUG_PARAM $KERNEL_EXTRA_PARAM"
if [ "$KERNEL" != "" ]; then
	QEMU_KERNEL="-kernel $KERNEL --append \"$KERNEL_PARAM\""
else
	QEMU_INITRD=""
fi

echo "$KERNEL"

if [ "$MEM" = "" ]; then
        MEM=1024
fi

CMD="$QEMU_CMD -nographic \
	-smp $SMP \
	-m $MEM \
	$QEMU_KERNEL \
	$QEMU_INITRD \
	$QEMU_IMG \
	$QEMU_NET \
	$QEMU_EXTRA_PARAM \
	$QEMU_DEBUG_PARAM \
	"
echo "$CMD"
bash -c "$CMD"
