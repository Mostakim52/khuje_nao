# PowerShell script to get SHA-1 fingerprint for debug keystore
# This script helps you get the SHA-1 fingerprint needed for Google Sign-In

Write-Host "Getting SHA-1 fingerprint from debug keystore..." -ForegroundColor Cyan

$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "Debug keystore not found at: $keystorePath" -ForegroundColor Yellow
    Write-Host "Creating debug keystore..." -ForegroundColor Cyan
    
    # Try to find Java
    $javaHome = $env:JAVA_HOME
    if (-not $javaHome) {
        # Common Java installation paths
        $possiblePaths = @(
            "$env:ProgramFiles\Android\Android Studio\jbr",
            "$env:ProgramFiles\Java",
            "${env:ProgramFiles(x86)}\Java",
            "$env:LOCALAPPDATA\Android\Sdk\jbr"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path "$path\bin\keytool.exe") {
                $javaHome = $path
                break
            }
        }
    }
    
    if (-not $javaHome) {
        Write-Host "Java not found. Please run 'flutter build appbundle' first to generate the keystore." -ForegroundColor Red
        Write-Host "Or install Java and set JAVA_HOME environment variable." -ForegroundColor Yellow
        exit 1
    }
    
    $keytoolPath = "$javaHome\bin\keytool.exe"
    if (-not (Test-Path $keytoolPath)) {
        Write-Host "keytool not found at: $keytoolPath" -ForegroundColor Red
        exit 1
    }
    
    # Create the .android directory if it doesn't exist
    $androidDir = Split-Path -Parent $keystorePath
    if (-not (Test-Path $androidDir)) {
        New-Item -ItemType Directory -Path $androidDir -Force | Out-Null
    }
    
    # Generate debug keystore
    & $keytoolPath -genkey -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}

# Try multiple methods to find keytool
$keytoolPath = $null
$javaHome = $env:JAVA_HOME

if ($javaHome -and (Test-Path "$javaHome\bin\keytool.exe")) {
    $keytoolPath = "$javaHome\bin\keytool.exe"
} else {
    # Try common Java paths
    $possiblePaths = @(
        "$env:ProgramFiles\Android\Android Studio\jbr",
        "$env:ProgramFiles\Java\jdk*",
        "${env:ProgramFiles(x86)}\Java\jdk*",
        "$env:LOCALAPPDATA\Android\Sdk\jbr",
        "$env:ProgramFiles\Eclipse Adoptium",
        "$env:ProgramFiles\Microsoft"
    )
    
    foreach ($basePath in $possiblePaths) {
        if (Test-Path $basePath) {
            $jdkPaths = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk*" -or $_.Name -like "jbr*" }
            foreach ($jdk in $jdkPaths) {
                $ktPath = Join-Path $jdk.FullName "bin\keytool.exe"
                if (Test-Path $ktPath) {
                    $keytoolPath = $ktPath
                    break
                }
            }
            if ($keytoolPath) { break }
        }
    }
}

if (-not $keytoolPath) {
    Write-Host ""
    Write-Host "keytool not found. Trying alternative method using Gradle..." -ForegroundColor Yellow
    Write-Host ""
    
    # Try using Gradle
    Push-Location android
    try {
        $output = & .\gradlew signingReport 2>&1 | Out-String
        if ($output -match "SHA1:\s*([A-F0-9:]+)") {
            $sha1 = $matches[1]
            Write-Host ""
            Write-Host "=== SHA-1 Fingerprint ===" -ForegroundColor Green
            Write-Host $sha1 -ForegroundColor White
            Write-Host ""
            Write-Host "Copy this SHA-1 and add it to Firebase Console:" -ForegroundColor Cyan
            Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor Cyan
            Write-Host "2. Select project: otp-khuje-nao" -ForegroundColor Cyan
            Write-Host "3. Project Settings > Your apps > Android app" -ForegroundColor Cyan
            Write-Host "4. Click 'Add fingerprint' and paste the SHA-1 above" -ForegroundColor Cyan
            exit 0
        }
    } catch {
        Write-Host "Gradle method also failed. Please run manually:" -ForegroundColor Red
        Write-Host "  cd android" -ForegroundColor Yellow
        Write-Host "  .\gradlew signingReport" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "Please run one of these commands manually:" -ForegroundColor Yellow
    Write-Host "  cd android && gradlew signingReport" -ForegroundColor Cyan
    Write-Host "  OR" -ForegroundColor Cyan
    Write-Host "  keytool -list -v -keystore `$env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android" -ForegroundColor Cyan
    exit 1
}

# Use keytool to get SHA-1
Write-Host "Using keytool at: $keytoolPath" -ForegroundColor Green
Write-Host ""

$output = & $keytoolPath -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android 2>&1

if ($LASTEXITCODE -eq 0) {
    if ($output -match "SHA1:\s*([A-F0-9:]+)") {
        $sha1 = $matches[1]
        Write-Host ""
        Write-Host "=== SHA-1 Fingerprint ===" -ForegroundColor Green
        Write-Host $sha1 -ForegroundColor White
        Write-Host ""
        Write-Host "Copy this SHA-1 and add it to Firebase Console:" -ForegroundColor Cyan
        Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor Cyan
        Write-Host "2. Select project: otp-khuje-nao" -ForegroundColor Cyan
        Write-Host "3. Project Settings > Your apps > Android app" -ForegroundColor Cyan
        Write-Host "4. Click 'Add fingerprint' and paste the SHA-1 above" -ForegroundColor Cyan
    } else {
        Write-Host "Could not parse SHA-1 from output:" -ForegroundColor Red
        Write-Host $output
    }
} else {
    Write-Host "Error running keytool:" -ForegroundColor Red
    Write-Host $output
    exit 1
}
