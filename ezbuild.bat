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

set CC=clang-cl
set CXX=clang-cl
set CFLAGS=-flto
set CXXFLAGS=-flto

REM Run dav1d.cmd manually first before compiling, or remove -DAVIF_CODEC_DAV1D=LOCAL. For some reason, dav1d doesn't compile inside cmake or when dav1d.cmd is run inside a script.

call cmake --fresh -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_DAV1D=LOCAL -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON
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