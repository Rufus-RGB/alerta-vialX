# Instala todo lo necesario para trabajar en Alerta Vial en un PC Windows nuevo.
# Uso (PowerShell normal, no hace falta administrador):
#   irm https://raw.githubusercontent.com/Rufus-RGB/alerta-vialX/main/scripts/instalar_portatil.ps1 | iex
# Se puede correr varias veces: lo que ya está instalado se salta.

$ErrorActionPreference = 'Stop'
$VersionFlutter = '3.47.7'
$RutaFlutter = 'C:\src\flutter'
$RutaProyecto = 'C:\proyectos\alerta-vialX'
$Repo = 'https://github.com/Rufus-RGB/alerta-vialX.git'
$SitioWeb = 'https://alerta-vialx.vercel.app'
$UrlSupabase = 'https://qyqniksgktaubqqqnhev.supabase.co'

function Paso($texto) { Write-Host "`n==> $texto" -ForegroundColor Yellow }
function Listo($texto) { Write-Host "    OK  $texto" -ForegroundColor Green }

function Refrescar-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Agregar-PathUsuario($ruta) {
  $actual = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $actual) { $actual = '' }
  if (($actual -split ';') -notcontains $ruta) {
    [Environment]::SetEnvironmentVariable('Path', ($actual.TrimEnd(';') + ';' + $ruta).TrimStart(';'), 'User')
  }
  Refrescar-Path
}

# ---------------- 1. Programas (winget) ----------------
Paso 'Programas'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'No se encontró winget. Instala "App Installer" desde Microsoft Store y vuelve a correr el script.'
}
$programas = @(
  @{ Id = 'Git.Git'; Nombre = 'Git' },
  @{ Id = 'Google.AndroidStudio'; Nombre = 'Android Studio' },
  @{ Id = 'Microsoft.VisualStudioCode'; Nombre = 'Visual Studio Code' },
  @{ Id = 'Google.Chrome'; Nombre = 'Google Chrome' },
  @{ Id = 'OpenJS.NodeJS.LTS'; Nombre = 'Node.js (para npx vercel)' }
)
foreach ($p in $programas) {
  winget list --id $p.Id -e --accept-source-agreements *> $null
  if ($LASTEXITCODE -eq 0) { Listo "$($p.Nombre) ya estaba"; continue }
  Write-Host "    Instalando $($p.Nombre)..."
  winget install --id $p.Id -e --silent --accept-package-agreements --accept-source-agreements
  Listo $p.Nombre
}
Refrescar-Path

# ---------------- 2. Flutter ----------------
Paso "Flutter $VersionFlutter"
if (-not (Test-Path "$RutaFlutter\bin\flutter.bat")) {
  New-Item -ItemType Directory -Force (Split-Path $RutaFlutter) | Out-Null
  git clone --depth 1 --branch $VersionFlutter https://github.com/flutter/flutter.git $RutaFlutter
}
Agregar-PathUsuario "$RutaFlutter\bin"
flutter config --no-analytics | Out-Null
Listo 'Flutter en el PATH'

# ---------------- 3. Android SDK ----------------
Paso 'Android SDK'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
if (-not (Test-Path "$sdk\platform-tools")) {
  Write-Host ''
  Write-Host '    Falta el Android SDK. Haz esto una sola vez:' -ForegroundColor Cyan
  Write-Host '      1. Abre Android Studio (menú Inicio).'
  Write-Host '      2. En el asistente elige "Standard" y deja que descargue todo.'
  Write-Host '      3. En la pantalla de bienvenida: More Actions > SDK Manager > pestaña SDK Tools,'
  Write-Host '         marca "Android SDK Command-line Tools" y "NDK (Side by side)", y Apply.'
  Write-Host '      4. Vuelve a correr este mismo comando.'
  Write-Host ''
  return
}
flutter config --android-sdk $sdk | Out-Null
Agregar-PathUsuario "$sdk\platform-tools"
Listo "SDK en $sdk"
Write-Host '    Acepta las licencias de Android (responde y a todo):' -ForegroundColor Cyan
flutter doctor --android-licenses

# ---------------- 4. Proyecto ----------------
Paso 'Proyecto'
if (-not (Test-Path "$RutaProyecto\.git")) {
  New-Item -ItemType Directory -Force (Split-Path $RutaProyecto) | Out-Null
  git clone $Repo $RutaProyecto
} else {
  git -C $RutaProyecto pull --ff-only
}
if (-not (git -C $RutaProyecto config user.email)) {
  $correo = Read-Host '    Correo para tus commits de Git'
  $nombre = Read-Host '    Nombre para tus commits de Git'
  git config --global user.email $correo
  git config --global user.name $nombre
}
Listo $RutaProyecto

# ---------------- 5. Claves de Supabase ----------------
Paso 'Configuración de Supabase'
$config = "$RutaProyecto\config\supabase.json"
if (-not (Test-Path $config)) {
  # La clave publicable es pública: ya va dentro de la web publicada, así que se toma de ahí.
  $clave = $null
  try {
    $js = (Invoke-WebRequest "$SitioWeb/main.dart.js" -UseBasicParsing).Content
    $m = [regex]::Match($js, '"(sb_publishable_[A-Za-z0-9_-]{10,}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)"')
    if ($m.Success) { $clave = $m.Groups[1].Value }
  } catch {}
  if (-not $clave) { $clave = Read-Host '    Pega la Publishable key de Supabase (Settings > API Keys)' }
  $json = @{ SUPABASE_URL = $UrlSupabase; SUPABASE_ANON_KEY = $clave } | ConvertTo-Json
  [IO.File]::WriteAllText($config, $json)
}
Listo 'config\supabase.json'

# ---------------- 6. Dependencias y revisión ----------------
Paso 'Dependencias'
Push-Location $RutaProyecto
flutter pub get
Pop-Location
code --install-extension Dart-Code.flutter 2>$null | Out-Null
Listo 'Extensión de Flutter para VS Code'

Paso 'Revisión final'
flutter doctor

Write-Host "`nTodo listo. Para correr la app:" -ForegroundColor Green
Write-Host "  cd $RutaProyecto"
Write-Host '  flutter run -d chrome --dart-define-from-file=config/supabase.json'
Write-Host 'Cierra y vuelve a abrir la terminal para que el PATH nuevo quede activo.'
