$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Api = Join-Path $Root 'services\api'

function Fail($Message) {
  Write-Host "`nERROR: $Message" -ForegroundColor Red
  Read-Host 'Press Enter to close'
  exit 1
}

try {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Fail 'Node.js is not installed.' }
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Fail 'npm is not installed.' }
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Fail 'Docker Desktop is not installed or not running.' }
  docker info *> $null
  if ($LASTEXITCODE -ne 0) { Fail 'Start Docker Desktop, then run this file again.' }

  $envFile = Join-Path $Api '.env'
  if (-not (Test-Path $envFile)) {
    $secretBytes = New-Object byte[] 48
    [Security.Cryptography.RandomNumberGenerator]::Fill($secretBytes)
    $jwtSecret = [Convert]::ToBase64String($secretBytes)
    @"
DATABASE_URL=postgresql://aurora:aurora@localhost:5432/aurora?schema=public
JWT_SECRET=$jwtSecret
PORT=3000
CORS_ORIGIN=*
NODE_ENV=development
"@ | Set-Content -Path $envFile -Encoding UTF8
  }

  Push-Location $Root
  docker compose -f infrastructure/docker-compose.dev.yml up -d db
  Pop-Location

  Push-Location $Api
  npm ci
  npx prisma generate
  npx prisma migrate deploy
  Pop-Location

  $ipv4 = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' } |
    Sort-Object InterfaceMetric |
    Select-Object -First 1 -ExpandProperty IPAddress
  if (-not $ipv4) { $ipv4 = '<YOUR-PC-IP>' }

  Write-Host "`nPhone server URL: http://${ipv4}:3000/api" -ForegroundColor Yellow
  Write-Host 'Keep this window open while using Aurora.' -ForegroundColor Yellow
  Push-Location $Api
  npm run start:dev
  Pop-Location
} catch {
  Fail $_.Exception.Message
}
