#!/bin/sh

SOURCE="fdk-aac-2.0.1"
FAT="fdk-aac-fat-iOS"
SCRATCH="scratch"
THIN=`pwd`/"thin"

ARCHS="arm64 x86_64 i386 armv7"
DEPLOYMENT_TARGET="7.0"

CONFIGURE_FLAGS="--enable-static --disable-shared --with-pic=yes"

if [ ! `which gas-preprocessor.pl` ]
then
    echo 'gas-preprocessor.pl not found.'
    exit 1
fi

CWD=`pwd`
cd $SOURCE
autoreconf -i
cd $CWD

# 编译
for ARCH in $ARCHS
do
    echo "building $ARCH..."
    mkdir -p "$SCRATCH/$ARCH"
    cd "$SCRATCH/$ARCH"

    CFLAGS="-arch $ARCH"

    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="iPhoneSimulator"
        CPU=
        if [ "$ARCH" = "i386" ]
        then
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=i386-apple-darwin"
        else
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=x86_64-apple-darwin"
        fi
    else
        PLATFORM="iPhoneOS"
        if [ "$ARCH" = "arm64" ]
        then
            HOST="--host=aarch64-apple-darwin"
        else
            HOST="--host=arm-apple-darwin"
        fi
        CFLAGS="$CFLAGS -fembed-bitcode"
    fi

    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    CC="xcrun -sdk $XCRUN_SDK clang"
    AS="$CWD/$SOURCE/extras/gas-preprocessor.pl $CC"
    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"

    $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        $HOST \
        $CPU \
        CC="$CC" \
        CXX="$CC" \
        CPP="$CC -E" \
        AS="$AS" \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CPPFLAGS="$CFLAGS" \
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
