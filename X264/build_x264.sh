#!/bin/sh

SOURCE="x264"
FAT="x264-fat-iOS"
SCRATCH="scratch"
THIN=`pwd`/"thin"

ARCHS="arm64 x86_64 i386 armv7"
DEPLOYMENT_TARGET="7.0"

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli"

if [ ! `which nasm` ]
then
    echo "nasm not found."
    exit 1
fi

CWD=`pwd`

# 编译
for ARCH in $ARCHS
do
    echo "building $ARCH..."
    mkdir -p "$SCRATCH/$ARCH"
    cd "$SCRATCH/$ARCH"

    CFLAGS="-arch $ARCH"
    ASFLAGS=

    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="iPhoneSimulator"
        CPU=
        if [ "$ARCH" = "x86_64" ]
        then
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=x86_64-apple-darwin"
        else
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=i386-apple-darwin"
        fi
    else
        PLATFORM="iPhoneOS"
        if [ $ARCH = "arm64" ]
        then
            HOST="--host=aarch64-apple-darwin"
            XARCH="-arch aarch64"
        else
            HOST="--host=arm-apple-darwin"
            XARCH="-arch arm"
        fi
        CFLAGS="$CFLAGS -fembed-bitcode -mios-version-min=$DEPLOYMENT_TARGET"
        ASFLAGS="$CFLAGS"
    fi

    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    CC="xcrun -sdk $XCRUN_SDK clang"
    if [ $PLATFORM = "iPhoneOS" ]
    then
        export AS="$CWD/$SOURCE/tools/gas-preprocessor.pl $XARCH -- $CC"
    else
        export -n AS
    fi
    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"

    CC=$CC $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        $HOST \
        --extra-cflags="$CFLAGS" \
        --extra-asflags="$ASFLAGS" \
        --extra-ldflags="$LDFLAGS" \
        --prefix="$THIN/$ARCH"

    make -j6 install
    cd $CWD
done

# 合并
echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`
cd $THIN/$1/lib
for LIB in *.a
do
    cd $CWD
    lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
done

cd $CWD
cp -rf $THIN/$1/include $FAT

# 验证
cd $FAT/lib
for LIB in *.a
do
    lipo -info $LIB
done