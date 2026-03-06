#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Genera un APK de debug con la URL del backend Ngrok baked-in.

.DESCRIPTION
  Compila la app Flutter en modo debug con --dart-define para que
  AppConfig.baseUrl use el túnel de Ngrok.

.PARAMETER NgrokUrl
  URL HTTPS del túnel Ngrok. Ej: https://abc-123.ngrok-free.app
  Si no se pasa, usa la IP local 192.168.x.x (pide confirmación).

.EXAMPLE
  # Con Ngrok estático
  .\build-apk.ps1 -NgrokUrl "https://abc-123.ngrok-free.app"

  # Sin parámetro → detecta IP local automáticamente
  .\build-apk.ps1
#>

param(
  [string]$NgrokUrl = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolver URL del backend ─────────────────────────────────────────────────
if ($NgrokUrl -eq "") {
  # Detectar IP local del host (útil para dispositivos en la misma red WiFi)
  $localIp = (
    Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback|Bluetooth|vEthernet" } |
    Select-Object -First 1
  ).IPAddress

  Write-Host ""
  Write-Host "⚠️  No se especificó -NgrokUrl." -ForegroundColor Yellow
  Write-Host "   IP local detectada: $localIp" -ForegroundColor Cyan
  Write-Host "   La app usará: http://$($localIp):3000" -ForegroundColor Cyan
  Write-Host ""
  $confirm = Read-Host "¿Continuar con la IP local? [s/N]"
  if ($confirm -notmatch "^[sS]$") {
    Write-Host ""
    Write-Host "Uso: .\build-apk.ps1 -NgrokUrl `"https://abc-123.ngrok-free.app`"" -ForegroundColor Green
    exit 0
  }
  $apiUrl = "http://$($localIp):3000"
} else {
  # Normalizar: quitar trailing slash
  $apiUrl = $NgrokUrl.TrimEnd("/")

  # Validación básica
  if ($apiUrl -notmatch "^https://") {
    Write-Error "❌ La URL de Ngrok debe comenzar con https://"
    exit 1
  }
}

# ── Info pre-build ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🎧 MusicParty — Build APK Debug" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🌐 API_URL : $apiUrl" -ForegroundColor Cyan
Write-Host "  📦 Modo    : debug" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# ── Cambiar al directorio mobile si se ejecuta desde otro lugar ──────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# ── Construir APK ────────────────────────────────────────────────────────────
flutter build apk --debug `
  --dart-define="API_URL=$apiUrl"

if ($LASTEXITCODE -ne 0) {
  Write-Error "❌ flutter build apk falló (exit $LASTEXITCODE)"
  exit $LASTEXITCODE
}

# ── Mostrar ubicación del APK ─────────────────────────────────────────────────
$apkPath = Join-Path $scriptDir "build\app\outputs\flutter-apk\app-debug.apk"
$apkSize  = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  ✅ APK generado: $apkSize MB" -ForegroundColor Green
Write-Host "  📂 $apkPath" -ForegroundColor White
Write-Host ""
Write-Host "  Opciones para distribuir a testers:" -ForegroundColor DarkGray
Write-Host "  • WhatsApp/Telegram: enviarte el archivo" -ForegroundColor Gray
Write-Host "  • Google Drive: subir y compartir enlace" -ForegroundColor Gray
Write-Host "  • Cable USB: copiar al almacenamiento del teléfono" -ForegroundColor Gray
Write-Host "  • ADB (USB debug): adb install $apkPath" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
