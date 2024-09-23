@echo off
setlocal

REM Run vcvarsall.bat with x64 architecture to set up the environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Exit on error
set ERRORLEVEL=0
if NOT "%ERRORLEVEL%" == "0" (
    exit /b %ERRORLEVEL%
)

REM Build process

REM Remove build dirs if they already exist
set dirs=SVT-AV1 aom libjpeg-turbo libwebp libxml2 libyuv zlib libpng
for %%d in (%dirs%) do (
    if exist "ext\%%d" (
        rmdir /s /q "ext\%%d"
    )
)

cd ext

REM Set CC and CXX for libyuv to clang-cl
set CC=clang-cl
set CXX=clang-cl
call libyuv.cmd
call libsharpyuv.cmd
call libjpeg.cmd
call zlibpng.cmd
call svt.cmd
call aom_win.cmd
cd ..

call cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_AOM=LOCAL -DAVIF_CODEC_SVT=LOCAL -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON -DCMAKE_C_FLAGS="/DWIN32 /D_WINDOWS -flto" -DCMAKE_CXX_FLAGS="/DWIN32 /D_WINDOWS /GR /EHsc -flto"

call cmake --build build --parallel

exit /b 0
