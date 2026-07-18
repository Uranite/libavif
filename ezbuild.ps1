#Requires -Version 7.2

# Dependencies: Git, LLVM (clang + llvm-profdata), C++ Build Tools, Perl, CMake, Meson, Ninja

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$env:PATH = 'C:\Program Files\LLVM\bin;' + $env:PATH
if (Test-Path 'C:\Program Files\NASM\nasm.exe') { $env:PATH = 'C:\Program Files\NASM;' + $env:PATH }
elseif (Test-Path "$env:LOCALAPPDATA\bin\NASM\nasm.exe") { $env:PATH = "$env:LOCALAPPDATA\bin\NASM;" + $env:PATH }
$env:CC = 'clang'
$env:CXX = 'clang++'
$env:CFLAGS = '-flto -fuse-ld=lld -O3 -DNDEBUG -march=znver2'
$env:CXXFLAGS = '-flto -fuse-ld=lld -O3 -DNDEBUG -march=znver2'

Set-Location "$PSScriptRoot/ext"

if (Test-Path dav1d/.git) { git -C dav1d pull } else { git clone --depth 300 https://code.videolan.org/videolan/dav1d.git dav1d }
$dav1dArgs = @('--default-library=static', '--buildtype', 'release', '-Ddebug=false', '-Doptimization=3',
    '-Denable_tools=false', '-Denable_tests=false', '-Db_ndebug=true',
    "-Dc_args=$env:CFLAGS", "-Dcpp_args=$env:CXXFLAGS", '-Db_lto=true')
if (Test-Path dav1d/build) {
    meson setup --reconfigure @dav1dArgs dav1d/build dav1d
} else {
    meson setup @dav1dArgs dav1d/build dav1d
}
meson compile -C dav1d/build

if (Test-Path aom/.git) { git -C aom pull } else { git clone --depth 300 https://aomedia.googlesource.com/aom aom }
cmake -G Ninja -S aom -B aom/build.libavif -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release `
    -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 `
    "-DCMAKE_C_FLAGS=$env:CFLAGS" "-DCMAKE_CXX_FLAGS=$env:CXXFLAGS"
ninja -C aom/build.libavif

if (Test-Path SVT-AV1/.git) { git -C SVT-AV1 pull } else { git clone --depth 300 --branch ghostrobot https://github.com/juliobbv-p/svt-av1-hdr.git SVT-AV1 }
$pgoData = "$PSScriptRoot/ext/SVT-AV1/svt_pgo_data"
$profdata = "$pgoData/default.profdata"
if (Test-Path SVT-AV1/svt_pgo_data) { Remove-Item -Recurse -Force SVT-AV1/svt_pgo_data }
New-Item -ItemType Directory SVT-AV1/svt_pgo_data | Out-Null
if (Test-Path SVT-AV1/build_pgo_gen) { Remove-Item -Recurse -Force SVT-AV1/build_pgo_gen }
cmake -G Ninja -S SVT-AV1 -B SVT-AV1/build_pgo_gen -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF `
    -DSVT_AV1_LTO=OFF -DENABLE_AVX512=ON -DBUILD_APPS=ON -DLOG_QUIET=ON `
    "-DCMAKE_C_FLAGS_RELEASE=$env:CFLAGS -fprofile-generate=$pgoData" `
    "-DCMAKE_CXX_FLAGS_RELEASE=$env:CXXFLAGS -fprofile-generate=$pgoData"
ninja -C SVT-AV1/build_pgo_gen

$webm = "$PSScriptRoot/Netflix_FoodMarket2_4096x2160_60fps_10bit_420.webm"
$y4m = "$PSScriptRoot/Netflix_FoodMarket2_1920x1080_60fps_10bit_420_96f.y4m"
if (!(Test-Path $webm)) { Invoke-WebRequest -Uri 'https://media.xiph.org/video/derf/webm/Netflix_FoodMarket2_4096x2160_60fps_10bit_420.webm' -OutFile $webm }
if ((Get-FileHash $webm -Algorithm SHA256).Hash -ne 'F625E9460AA7964855D00C4CAD535D910EC4EEC7594B4CCEB5611CB00CC5F75B') { throw 'PGO clip hash mismatch.' }
if (!(Test-Path $y4m)) {
    ffmpeg -hide_banner -v error -y -nostdin -i $webm -frames:v 96 `
        -vf 'scale=1920:1080:flags=lanczos+accurate_rnd+full_chroma_int:param0=4' `
        -pix_fmt yuv420p10le -strict -1 -f yuv4mpegpipe $y4m
}
.\SVT-AV1\Bin\Release\SvtAv1EncApp.exe -i $y4m -b NUL --preset 3
llvm-profdata merge --sparse=true -o $profdata $pgoData

if (Test-Path SVT-AV1/build_pgo_use) { Remove-Item -Recurse -Force SVT-AV1/build_pgo_use }
cmake -G Ninja -S SVT-AV1 -B SVT-AV1/build_pgo_use -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF `
    -DSVT_AV1_LTO=OFF -DENABLE_AVX512=ON -DBUILD_APPS=OFF -DLOG_QUIET=ON `
    "-DCMAKE_C_FLAGS_RELEASE=$env:CFLAGS -fprofile-use=$profdata" `
    "-DCMAKE_CXX_FLAGS_RELEASE=$env:CXXFLAGS -fprofile-use=$profdata"
ninja -C SVT-AV1/build_pgo_use
New-Item -ItemType Directory -Force SVT-AV1/include/svt-av1 | Out-Null
Copy-Item SVT-AV1/Source/API/*.h SVT-AV1/include/svt-av1 -Force

Set-Location $PSScriptRoot
cmake --fresh -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF `
    "-DCMAKE_C_FLAGS=$env:CFLAGS" "-DCMAKE_CXX_FLAGS=$env:CXXFLAGS" `
    -DAVIF_CODEC_DAV1D=LOCAL -DAVIF_LIBXML2=LOCAL -DAVIF_CODEC_AOM=LOCAL -DAVIF_CODEC_SVT=LOCAL `
    -DAVIF_LIBYUV=LOCAL -DAVIF_LIBSHARPYUV=LOCAL -DAVIF_JPEG=LOCAL -DAVIF_ZLIBPNG=LOCAL -DAVIF_BUILD_APPS=ON
ninja -C build
