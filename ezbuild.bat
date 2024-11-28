@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, and Ninja

REM Set up the environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
if errorlevel 1 goto error

REM Remove build dirs if they already exist
for %%d in (build) do (
    if exist "%%d" (
        rmdir /s /q "%%d"
        if errorlevel 1 goto error
    )
)

for %%d in (SVT-AV1 aom libjpeg-turbo libwebp libxml2 libyuv zlib libpng libargparse) do (
    if exist "ext\%%d" (
        rmdir /s /q "ext\%%d"
        if errorlevel 1 goto error
    )
)

cd ext

REM Set the compiler to Clang-CL for free performance
set CC=clang-cl
set CXX=clang-cl

call libyuv.cmd
if errorlevel 1 goto error
call libsharpyuv.cmd
if errorlevel 1 goto error
call libjpeg.cmd
if errorlevel 1 goto error
call zlibpng.cmd
if errorlevel 1 goto error
call libargparse.cmd
if errorlevel 1 goto error
call aom.cmd
if errorlevel 1 goto error

cd ..

call cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_AOM=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON -DCMAKE_CXX_FLAGS_RELEASE="/MD /O2 /Ob2 /DNDEBUG -flto" -DCMAKE_C_FLAGS_RELEASE="/MD /O2 /Ob2 /DNDEBUG -flto"
if errorlevel 1 goto error

call cmake --build build --parallel
if errorlevel 1 goto error

goto end

:error
echo An error occurred. Pausing the script.
pause

goto end

:end
echo Script completed successfully.
pause
