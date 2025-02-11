# ------- Open PowerShell Window --------------------
pwsh

# ------- Set Up Python -----------------------------

# Set up the Python environment (customizable name)
python -m venv .venv --prompt rieee-ess-env

# Activate virtual environment
source .venv/bin/activate

# Install required packages
python -m pip install ./tools/ # DO NOT EDIT
python -m pip install -e ./design/ # Your team may edit

# ------- Set Up Docker -----------------------------
$dockerDmgPath = "$HOME/Downloads/Docker.dmg"

# Check if Docker DMG exists before mounting
if (Test-Path $dockerDmgPath) {
    hdiutil attach $dockerDmgPath -nobrowse
    cp -R /Volumes/Docker/Docker.app /Applications/
    hdiutil detach /Volumes/Docker
    open /Applications/Docker.app
} else {
    Write-Host "Error: Docker.dmg not found in ~/Downloads/" -ForegroundColor Red
    exit 1
}

# ------- Locate Serial Port ------------------------
# Ensure Docker is installed before running this step
$serialDevice = ls /dev/tty.* | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if serial port was detected
if ($serialDevice -eq $null) {
    Write-Host "Error: No serial device detected. Please check your connection." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Using Serial Device: $serialDevice"
    sudo chmod 777 $serialDevice
}

# ------- Create a Deployment ------------------------
python -m ectf25_design.gen_secrets global.secrets 1 3 4

# Build Docker container
docker build -t build-decoder ./decoder

# ------- Build a Decoder ----------------------------
docker run --rm -v ./decoder/:/decoder -v ./global.secrets:/global.secrets -v ./deadbeef_build:/out -e DECODER_ID=0xdeadbeef build-decoder

# ------- Generate a Subscription Update -------------
python -m ectf25_design.gen_subscription global.secrets deadbeef_c1.sub 0xDEADBEEF 32 128 1

# ------- Flash the Decoder Firmware -----------------
$daplinkPath = "/Volumes/DAPLINK"

# Ensure DAPLink is mounted before flashing
if (Test-Path $daplinkPath) {
    cp "$HOME/Downloads/special_daplink_firmware.hex" $daplinkPath/
    diskutil unmount $daplinkPath
    Write-Host "Waiting for board to reboot..."
    Start-Sleep -Seconds 10
} else {
    Write-Host "Error: DAPLink device not detected. Please check connection." -ForegroundColor Red
    exit 1
}

# Flash the Decoder Firmware
python -m ectf25.utils.flash ./deadbeef_build/max78000.bin $serialDevice