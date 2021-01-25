#!/bin/sh

# directories
SOURCE="ffmpeg-n4.3.1"
FAT="FFmpeg-iOS"
SCRATCH="scratch"
THIN=`pwd`/"thin"
X264=`pwd`/../X264/x264-fat-iOS
FDK_AAC=`pwd`/../fdk-aac/fdk-aac-fat-iOS

ARCHS="arm64 armv7 x86_64 i386"
DEPLOYMENT_TARGET="8.0"

if [ ! `which yasm` ]
then
    echo 'Yasm not found'
    exit 1
fi

if [ ! `which gas-preprocessor.pl` ]
then
    echo 'gas-preprocessor.pl not found.'
    exit 1
fi

if [ ! -r $SOURCE ]
then
    echo 'FFmpeg source not found.'
    exit 1
fi

CONFIGURE_FLAGS="--disable-shared
                 --enable-static
                 --disable-programs
                 --disable-stripping
                 --disable-ffmpeg
                 --disable-ffplay
                 --disable-ffprobe
                 --disable-avdevice
                 --disable-devices
                 --disable-indevs
                 --disable-outdevs
                 --disable-debug
                 --disable-asm
                 --disable-yasm
                 --disable-doc
                 --enable-pic
                 --enable-small
                 --enable-dct
                 --enable-dwt
                 --enable-lsp
                 --enable-mdct
                 --enable-rdft
                 --enable-fft
                 --enable-version3
                 --disable-filters
                 --disable-postproc
                 --disable-bsfs
                 --enable-bsf=aac_adtstoasc
                 --enable-bsf=h264_mp4toannexb
                 --disable-encoders
                 --enable-encoder=pcm_s16le
                 --enable-encoder=aac
                 --enable-encoder=libvo_aacenc
                 --disable-decoders
                 --enable-decoder=aac
                 --enable-decoder=mp3
                 --enable-decoder=pcm_s16le
                 --disable-parsers
                 --enable-parser=aac
                 --disable-muxers
                 --enable-muxer=flv
                 --enable-muxer=wav
                 --enable-muxer=adts
                 --disable-demuxers
                 --enable-demuxer=flv
                 --enable-demuxer=wav
                 --enable-demuxer=aac
                 --disable-protocols
                 --enable-protocol=rtmp
                 --enable-protocol=file
                 --enable-nonfree
                 --enable-libfdk_aac
                 --enable-gpl
                 --enable-libx264
                 --enable-cross-compile"

CWD=`pwd`
for ARCH in $ARCHS
do
    echo "building $ARCH..."
    mkdir -p "$SCRATCH/$ARCH"
    cd "$SCRATCH/$ARCH"

    CFLAGS="-arch $ARCH"
    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="iPhoneSimulator"
        CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
    else
        PLATFORM="iPhoneOS"
        CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
        if [ "$ARCH" = "arm64" ]
        then
            EXPORT="GASPP_FIX_XCODE5=1"
        fi
    fi

    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    CC="xcrun -sdk $XCRUN_SDK clang"

    # force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
    if [ "$ARCH" = "arm64" ]
    then
        AS="gas-preprocessor.pl -arch aarch64 -- $CC"
    else
        AS="gas-preprocessor.pl -- $CC"
    fi

    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"
    if [ "$X264" ]
    then
        CFLAGS="$CFLAGS -I$X264/include"
        LDFLAGS="$LDFLAGS -L$X264/lib"
    fi
    if [ "$FDK_AAC" ]
    then
        CFLAGS="$CFLAGS -I$FDK_AAC/include"
        LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
    fi

    $CWD/$SOURCE/configure \
        --target-os=darwin \
        --arch=$ARCH \
        --cc="$CC" \
        --as="$AS" \
        $CONFIGURE_FLAGS \
        --extra-cflags="$CFLAGS" \
        --extra-ldflags="$LDFLAGS" \
        --prefix="$THIN/$ARCH" \

    make -j6 install
    cd $CWD
done

echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`
cd $THIN/$1/lib
for LIB in *.a
do
    cd $CWD
    lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
done

cd $CWD
cp -rf $THIN/$1/include $FAT

# 验证
cd $FAT/lib
for LIB in *.a
do
    lipo -info $LIB
done

echo Done
