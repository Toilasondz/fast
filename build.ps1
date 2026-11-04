# build.ps1 — 1-Click Cross-compile VSFastColor.dylib on Windows
$ErrorActionPreference = "Stop"

$SRC_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$TOOL_ROOT = "C:\Users\hson\.gemini\antigravity\scratch\VideoStarTool"
$SDK_DIR  = "$TOOL_ROOT\sdk\iPhoneOS15.6.sdk"
$CLANG    = "$TOOL_ROOT\tools\llvm-mingw-20261020-msvcrt-x86_64\bin\clang.exe"
$OUT_DIR  = "$SRC_DIR\out"
$OUT_DYLIB = "$SRC_DIR\VSFastColor.dylib"

Write-Host "========================================="
Write-Host " Building VSFastColor.dylib on Windows"
Write-Host " Compiler: $CLANG"
Write-Host " SDK:      $SDK_DIR"
Write-Host "========================================="

if (-not (Test-Path $CLANG)) {
    Write-Error "clang.exe not found at $CLANG."
    exit 1
}

if (-not (Test-Path "$SDK_DIR\usr\include")) {
    Write-Error "iOS SDK not found at $SDK_DIR."
    exit 1
}

New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null

$SOURCES = @(
    "VSFastColor.m",
    "VSColorTurboEngine.m",
    "VSFastColorOverlay.m"
)

$OBJS = @()
foreach ($src in $SOURCES) {
    $srcPath = "$SRC_DIR\$src"
    $objPath = "$OUT_DIR\" + [System.IO.Path]::ChangeExtension($src, ".o")
    Write-Host "--> Compiling $src..."
    & $CLANG -target arm64-apple-ios14.0 -isysroot $SDK_DIR -fobjc-arc -O2 -c $srcPath -o $objPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compile $src"
        exit 1
    }
    $OBJS += $objPath
}

Write-Host "--> Linking VSFastColor.dylib..."
$LINK_ARGS = @(
    "-target", "arm64-apple-ios14.0",
    "-fuse-ld=lld",
    "-isysroot", $SDK_DIR,
    "-shared",
    "-dynamiclib",
    "-Xlinker", "-undefined",
    "-Xlinker", "dynamic_lookup",
    "-Xlinker", "-install_name",
    "-Xlinker", "@rpath/VSFastColor.dylib",
    "-o", $OUT_DYLIB
) + $OBJS

& $CLANG $LINK_ARGS
if ($LASTEXITCODE -ne 0) {
    Write-Error "Linking failed."
    exit 1
}

$size = (Get-Item $OUT_DYLIB).Length
Write-Host ""
Write-Host "========================================="
Write-Host " BUILD SUCCESSFUL!"
Write-Host " Output : $OUT_DYLIB"
Write-Host " Size   : $([math]::Round($size/1KB,1)) KB ($size bytes)"
Write-Host " Target : arm64 (iOS 14.0+)"
Write-Host "========================================="
