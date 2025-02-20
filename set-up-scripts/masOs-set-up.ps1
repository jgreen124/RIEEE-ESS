# ------- Open PowerShell Window --------------------
pwsh

# ------- Set Up Python -----------------------------

# Set up the Python environment (customizable name)
python -m venv .venv --prompt rieee-ess-env

# Activate virtual environment
./.venv/bin/activate

# Install required packages
python -m pip install ./tools/ # DO NOT EDIT
python -m pip install -e ./design/ # Your team may edit

# ------- Set Up Docker -----------------------------

#Open docker desktop on mac :) (if its not already open)

# ------- Locate Serial Port ------------------------
# Ensure Docker is installed before running this step

# use command below to help locate the device (make sure it is plugged in)
ls -lt /dev/tty.* | head -10
# Maya's device (board 7): tty.usbmodem11202 


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
