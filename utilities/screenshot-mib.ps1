$projectRoot = "$(&git rev-parse --show-toplevel)";
$screenshotDir = "$projectRoot/screenshots"
New-Item -ItemType Directory -Path $screenshotDir -ErrorAction SilentlyContinue | Out-Null

$fileName = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
$screenshotName = "$screenshotDir/$fileName.png"

write-host "Taking screenshot"
ssh mib2 "export LD_LIBRARY_PATH=/eso/lib; export IPL_CONFIG_DIR=/etc/eso/production; /eso/bin/apps/dmdt ts 0 /tmp/sc.png;"

write-host "Copying"
scp mib2:/tmp/sc.png $screenshotName