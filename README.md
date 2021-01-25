# w_av_foundation

## 编译

开源库的源代码版本默认最新的release（尽量保持更新），以压缩包形式放在仓库中

默认编译架构是 arm64 x86_64 i386 armv7

编译脚本参考了[kewlbear](https://github.com/kewlbear)

### 编译fdk-aac

```
cd fdk-aac
tar xvf fdk-aac-2.0.1.tar.gz
sh build_fdk-aac.sh
```

编译最终结果在 fdk-aac-fat-iOS 文件夹中

### 编译x264

```
cd x264
tar xvf x264-20191217-2245-stable.tar.gz
sh build_x264.sh
```

编译最终结果在 x264-fat-iOS 文件夹中

### 编译FFmpeg

需要先编译好fdk-aac和x264

```
cd FFmpeg
tar xvf FFmpeg-n4.3.1.tar.gz
sh build_ffmpeg.sh
```

编译最终结果在 FFmpeg-iOS 文件夹中

