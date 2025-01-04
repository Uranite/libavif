@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, and Ninja

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

set CC=clang-cl
set CXX=clang-cl
set CFLAGS=-flto
set CXXFLAGS=-flto

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
