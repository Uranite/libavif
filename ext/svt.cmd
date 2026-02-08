: # If you want to use a local build of SVT-AV1, you must clone the SVT-AV1 repo in this directory first,
: # then set CMake's AVIF_CODEC_SVT to LOCAL.
: # cmake must be in your PATH.

: # The odd choice of comment style in this file is to try to share this script between *nix and win32.

: # Switch to a sh-like command if not running in windows
: ; $SHELL svt.sh
: ; exit $?

: # If you're running this on Windows, be sure you've already run this (from your VC2019 install dir):
: #    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"

git clone --depth 300 https://gitlab.com/AOMediaCodec/SVT-AV1.git

cd SVT-AV1

cmake --fresh -B build.libavif -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DSVT_AV1_LTO=OFF -DENABLE_AVX512=ON -DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG -O2" -DCMAKE_C_FLAGS_RELEASE="-DNDEBUG -O2"
cmake --build build.libavif
mkdir include\svt-av1
copy Source\API\*.h include\svt-av1

cd ..
