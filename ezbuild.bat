@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Note: The dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, NASM, and Ninja

REM Remove build dirs if they already exist
for %%d in (build) do (
    if exist "%%d" (
        rmdir /s /q "%%d"
        if errorlevel 1 goto error
    )
)

for %%d in (aom libargparse libjpeg-turbo libpng libwebp libyuv libxml2 zlib) do (
    if exist "ext\%%d" (
        rmdir /s /q "ext\%%d"
        if errorlevel 1 goto error
    )
)

cd ext

set CFLAGS=-flto
set CXXFLAGS=-flto

call aom.cmd
if errorlevel 1 goto error
call libargparse.cmd
if errorlevel 1 goto error
call libjpeg.cmd
if errorlevel 1 goto error
call libsharpyuv.cmd
if errorlevel 1 goto error
call libyuv.cmd
if errorlevel 1 goto error
call libxml2.cmd
if errorlevel 1 goto error
call zlibpng.cmd
if errorlevel 1 goto error

cd ..

REM Optional: Run dav1d.cmd manually and add -DAVIF_CODEC_DAV1D=LOCAL. For some reason, dav1d doesn't compile when dav1d.cmd is run inside a script.

call cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON
if errorlevel 1 goto error

call ninja -C build
if errorlevel 1 goto error

goto end

:error
echo An error occurred. Pausing the script.
pause

goto end

:end
echo Script completed successfully.
pause
