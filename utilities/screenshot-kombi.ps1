$projectRoot = "$(&git rev-parse --show-toplevel)";
$screenshotDir = "$projectRoot/screenshots"
New-Item -ItemType Directory -Path $screenshotDir -ErrorAction SilentlyContinue | Out-Null

$fileName = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
$screenshotName = "$screenshotDir/$($fileName)_kombi.png"

# Taking screenshot of the Kombi display means we have to actually screenshot the main display.
# To do this, we change the context of display 0 to -3 (the kombi map)
# We then screenshot
# Finally resetting the state of display 0 to return to normal use
write-host "Taking screenshot"
ssh mib2 "export LD_LIBRARY_PATH=/eso/lib; export IPL_CONFIG_DIR=/etc/eso/production; /eso/bin/apps/dmdt sc 0 -3;/eso/bin/apps/dmdt ts 0 /tmp/sc.png;/eso/bin/apps/dmdt sb 0;"
start-sleep 2
write-host "Copying to $screenshotName"
scp mib2:/tmp/sc.png $screenshotName