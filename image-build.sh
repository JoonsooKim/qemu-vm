bash image-mount.sh mount $ARCH
ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE bash image-modules.sh
bash image-mount.sh unmount $ARCH
