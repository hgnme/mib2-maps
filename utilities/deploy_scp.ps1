param (
  [switch] $deploy = $false,
  [switch] $backup = $false
)
$destPath = '/mnt/app/navigation/resources/app/vw/aus/';

#directories
$projectRoot = "$(&git rev-parse --show-toplevel)";

$mapBuilder = "$projectRoot/mib2-mapbuilder";
$mapConfigSrc = "$mapBuilder/rendered";
$stagingDir = "$projectRoot/deploy";
$mapStyleSrc = "$projectRoot/mapstyles";

#backup
$backupName = '{0:yyyyMMdd-HHmmss}' -f (Get-Date);
$backupRoot = "$projectRoot/backup";
$backupDir = "$backupRoot/$($backupName)";

Write-Host "Creating Directories";
New-Item -ItemType Directory $stagingDir -ErrorAction SilentlyContinue | Out-Null;
New-Item -ItemType Directory $backupRoot -ErrorAction SilentlyContinue | Out-Null;

Write-Host "Directories:";
Write-host "--> MapConfig Source: $mapConfigSrc";
Write-host "--> Staging target: $stagingDir";
if($deploy -eq $true -and $backup -eq $true) {
  Write-host "--> Backup target: $backupDir";
}

# Create folder of current release
# Copy file tree of AUS folder 

Write-Host "Begin Staging build";
Write-Host "--> Building MapConfigs";
&npm run --silent --prefix $mapBuilder buildmaps;
Write-Host "--> MapConfigs generated";
Write-Host "--> Emptying Staging Dir";
Remove-Item -Path "$stagingDir/*" -Recurse | out-null;
New-Item -ItemType Directory "$stagingDir/MapConfigs" | out-null;

Write-Host "--> Populating Staging Dir"
Copy-Item -Path ($mapStyleSrc + "/exitview") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/Font") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/gui") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/guidanceview") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/intersectionmap") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapConfigSrc + "/*") -Destination "$stagingDir/MapConfigs/" -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/MapConfigs/*.fcx") -Destination "$stagingDir/MapConfigs/" | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/MapConfigs/*.csv.gz") -Destination "$stagingDir/MapConfigs/" | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/Models") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/pcconfig") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/poi") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/res") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/roadicon") -Destination $stagingDir -Recurse -Exclude ("*.ps1", "*Copy*", "*.gz")| Out-Null;
Copy-Item -Path ($mapStyleSrc + "/signpost") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/textures") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/tti") -Destination $stagingDir -Recurse | Out-Null;
Copy-Item -Path ($mapStyleSrc + "/*.*") -Destination $stagingDir -Exclude ("*original*", "*.ps1", "*.md", "*.py", "*.sh", "*.bak")| Out-Null;

Write-host "--> Storing commit point in commit.txt";
$hash = &git rev-parse HEAD;
Set-Content -Path "$stagingDir/commit.txt" -value $hash;

Write-Host "Staging build complete";

if($deploy -eq $true) {
  Write-Host "Begin Deploy to MIB2";
  if($backup -eq $true) {
    Write-Host "-->Performing backup";
    New-Item -ItemType Directory $backupDir | Out-Null;
    scp -r mib2:$destPath $backupDir;
  }
  Write-Host "-->making mount-point writable";
  &ssh mib2 mount -uw /net/mmx/mnt/app;

  #Write-Host "--> emptying nav folder on mib2";
  #ssh mib2 rm -rf /mnt/app/navigation/resources/app/vw/aus/*;

  write-host "--> Copying to mib2";
  &scp -r $stagingDir/* mib2:/mnt/app/navigation/resources/app/vw/aus/;

  write-host "--> making mount-point read-only";
  &ssh mib2 mount -ur /net/mmx/mnt/app;

  write-host "--> Restarting AppStartATF";
  ssh mib2 slay AppStartATF;
  Write-Host "MIB Deploy complete";
}
Write-Host "Finished";