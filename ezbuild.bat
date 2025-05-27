@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Note: the dependencies are Git, LLVM, C++ Build Tools, Perl, CMake, and Ninja

REM Remove build dirs if they already exist
for %%d in (dav1d aom) do (
    if exist "ext\%%d" (
        rmdir /s /q "ext\%%d"
        if errorlevel 1 goto error
    )
)

REM call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
set PATH=C:\Program Files\LLVM\bin;%PATH%

set CC=clang
set CXX=clang

cd ext
call dav1d.cmd
cd ..

set "CFLAGS=-flto -march=x86-64-v3"
set "CXXFLAGS=-flto -march=x86-64-v3"

cd ext
call aom.cmd
cd ..

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
