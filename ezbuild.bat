@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, and Ninja

REM Set up the environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Remove build dirs if they already exist
for %%d in (build) do (
    if exist "%%d" (
        rmdir /s /q "%%d"
    )
)

for %%d in (SVT-AV1 aom libjpeg-turbo libwebp libxml2 libyuv zlib libpng libargparse) do (
    if exist "ext\%%d" (
        rmdir /s /q "ext\%%d"
    )
)

cd ext

REM Set the compiler to Clang-CL for free performance
set CC=clang-cl
set CXX=clang-cl

call libyuv.cmd
call libsharpyuv.cmd
call libjpeg.cmd
call zlibpng.cmd
call aom.cmd
call libxml2.cmd
call libargparse.cmd

cd ..

call cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_ENABLE_GAIN_MAP=ON -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON -DCMAKE_CXX_FLAGS_RELEASE="/MD /O2 /Ob2 /DNDEBUG -flto" -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /DNDEBUG -flto"
call cmake --build build --parallel

echo Script completed successfully.
pause
