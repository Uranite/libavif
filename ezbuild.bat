@echo off

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, Meson, and Ninja

REM call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
set PATH=C:\Program Files\LLVM\bin;%PATH%

set CC=clang
set CXX=clang

cd ext

set "CFLAGS=-march=x86-64-v3"
set "CXXFLAGS=-march=x86-64-v3"

if exist dav1d (
    pushd dav1d
    git pull
    popd
    meson setup --default-library=static --buildtype release -Denable_tools=false -Denable_tests=false -Db_lto=true dav1d/build dav1d
    meson compile -C dav1d/build
) else (
    call dav1d.cmd
)
cd ..

set "CFLAGS=-flto -march=x86-64-v3"
set "CXXFLAGS=-flto -march=x86-64-v3"

cd ext
if exist aom (
    pushd aom
    git pull
    popd
    cmake -G Ninja -S aom -B aom/build.libavif -DBUILD_SHARED_LIBS=OFF -DCONFIG_PIC=1 -DCMAKE_BUILD_TYPE=Release -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0
    cmake --build aom/build.libavif --config Release --parallel
) else (
    call aom.cmd
)

if exist SVT-AV1 (
    pushd SVT-AV1
    git pull
    popd
    cmake -G Ninja -S SVT-AV1 -B SVT-AV1/build.libavif -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DSVT_AV1_LTO=OFF -DENABLE_AVX512=ON -DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG -O2" -DCMAKE_C_FLAGS_RELEASE="-DNDEBUG -O2"
    cmake --build SVT-AV1/build.libavif
) else (
    call svt.cmd
)
cd ..

call cmake --fresh -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_DAV1D=LOCAL -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_CODEC_SVT=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON
if errorlevel 1 goto error

call cmake --build build --parallel
if errorlevel 1 goto error

goto end

:error
echo An error occurred. Pausing the script.
pause
goto :eof

:end
echo Script completed successfully.
pause
