@echo off

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, Meson, and Ninja

REM call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
set PATH=C:\Program Files\LLVM\bin;%PATH%

set CC=clang
set CXX=clang++

cd ext

if exist dav1d (
    pushd dav1d
    git pull
    popd
) else (
    git clone --depth 300 https://code.videolan.org/videolan/dav1d.git
)
meson setup --reconfigure --default-library=static --buildtype release -Ddebug=false -Doptimization=3 -Denable_tools=false -Denable_tests=false -Db_ndebug=true -Dc_args="-march=znver2" -Dcpp_args="-march=znver2" -Db_lto=true dav1d/build dav1d
meson compile -C dav1d/build

if exist aom (
    pushd aom
    git pull
    popd
) else (
    git clone --depth 300 https://aomedia.googlesource.com/aom
)
cmake -G Ninja -S aom -B aom/build.libavif -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DCMAKE_C_FLAGS="-flto -march=znver2" -DCMAKE_CXX_FLAGS="-flto -march=znver2"
ninja -C aom/build.libavif

if exist SVT-AV1 (
    pushd SVT-AV1
    git pull
    popd
) else (
    git clone --depth 300 https://gitlab.com/AOMediaCodec/SVT-AV1.git
)
cmake -G Ninja -S SVT-AV1 -B SVT-AV1/build.libavif -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DSVT_AV1_LTO=OFF -DENABLE_AVX512=ON -DBUILD_APPS=OFF -DCMAKE_CXX_FLAGS_RELEASE="-flto -O3 -DNDEBUG -march=znver2" -DCMAKE_C_FLAGS_RELEASE="-flto -O3 -DNDEBUG -march=znver2"
ninja -C SVT-AV1/build.libavif
mkdir SVT-AV1\include\svt-av1
copy SVT-AV1\Source\API\*.h SVT-AV1\include\svt-av1

cd ..

set "CFLAGS=-flto -O3 -DNDEBUG -march=znver2"
set "CXXFLAGS=-flto -O3 -DNDEBUG -march=znver2"

call cmake --fresh -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_DAV1D=LOCAL -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_CODEC_SVT=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON
if errorlevel 1 goto error

call ninja -C build
if errorlevel 1 goto error

goto end

:error
echo An error occurred. Pausing the script.
pause
goto :eof

:end
echo Script completed successfully.
pause
