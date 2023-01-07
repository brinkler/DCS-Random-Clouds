# Ændringer og hvad der skal ændres er i Cloud Preset.txt filen.

# Hvordan det så skal virke i praksis på server, det er op til jer - hvordan filen bliver ændret ved en mission reload, eller om mission reloades uafhængigt af missions tid, så bare fast hver anden dag kl et eller andet eller lign. 
# Attachment file type: unknown
# Cloud_Presets.miz
# 6.49 KB

# -- Sådan ser afsnittet ud i Mission filen.

#         ["clouds"] = 
#         {
#             ["density"] = 0,
# Expand
# Cloud_Presets.txt
# 2 KB

[CmdletBinding()]
param (
    # Mission file
    [String] $MIZ
)

Write-Host "Running random clouds on $MIZ"

#Launch command in powershell window: ./mission.ps1 E:\temp\*.miz 

#E:\temp\*.miz  or E:\temp\mymission_file.miz (if the script is in the same folder with all miz file just enter *.miz or mymission_file.miz skipping full path)

#find all miz file or specific one 
Get-ChildItem $MIZ | ForEach-Object {

    $_

    # Load miz file 
    try { $null = [IO.Compression.ZipFile] }
    catch { [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') }

    # Open miz file 
    try { $fileZip = [System.IO.Compression.ZipFile]::Open( $_, 'Update' ) }
    catch { throw "Another process has locked the '$_' file." }

    # Find the mission file within the miz file
    $fileZip.Entries | Where-Object { $_.FullName -EQ 'mission' }

    #read the contents of mission file to $mission_tmp 
    $desiredFile = [System.IO.StreamReader]($fileZip.Entries | Where-Object { $_.FullName -EQ 'mission' }).Open()
    $mission_tmp = $desiredFile.ReadToEnd()
    $desiredFile.Close()
    $desiredFile.Dispose()

    $clouds = Select-String  -Pattern '\["preset"\] = "(Rainy)?Preset\d+",' -InputObject $mission_tmp 
    $replaceValue = $clouds.Matches.Value

    Write-Host "Replacing Clouds : `n$replaceValue"
    
    $isItRainingRandom = Get-Random -Minimum 0 -Maximum 4
    $newCloudsValue = Get-Random -Minimum 1 -Maximum 27
    $newBaseValue = Get-Random -Minimum 4300 -Maximum 20000
    if ($isItRainingRandom -lt 1) {
        Write-Host "It is raining"
        $newCloudsValue = Get-Random -Minimum 1 -Maximum 3
        $newBaseValue = Get-Random -Minimum 2000 -Maximum 4000
        $newClouds = $replaceValue -replace '\["preset"\] = ".*",', "[`"preset`"] = `"RainyPreset$newCloudsValue`","
    }
    else {
        Write-Host "It is not raining"
        $newClouds = $replaceValue -replace '\["preset"\] = ".*",', "[`"preset`"] = `"Preset$newCloudsValue`","
    }
    Write-Host "replace : " $replaceValue
    Write-Host "with    : " $newClouds

    # Update cloud presets 
    $mission_tmp = $mission_tmp -replace [regex]::escape($replaceValue), $newClouds
    # Log result from replace
    $replacedClouds = Select-String  -Pattern '\["preset"\] = ".*",' -InputObject $mission_tmp -AllMatches 
    Write-Host "Replaced clouds`n" $replacedClouds.Matches.Value

    ## Next bit is essentially the same
    # do we need t replace base?
    Write-Host "`nReplace Base: `n"
    $base = Select-String  -Pattern '\["base"\] = \d+,' -InputObject $mission_tmp 
    $replaceBase = $base.Matches.Value
    
    $newBase = "[`"base`"] = $newBaseValue,"

    Write-Host "Replace base : " $replaceBase
    Write-Host "With         : " $newBase

    $mission_tmp = $mission_tmp -replace [regex]::escape($replaceBase), $newBase
    # Log result from replace
    $replacedBase = Select-String  -Pattern '\["base"\] = .*,' -InputObject $mission_tmp -AllMatches 
    Write-Host "Replaced base`n" $replacedBase.Matches.Value
    ## 

    # Re-open the file this time with streamwriter
    $desiredFile = [System.IO.StreamWriter]($fileZip.Entries | Where-Object { $_.FullName -EQ 'mission' }).Open()
    $desiredFile.BaseStream.SetLength(0)

    # Insert the $mission_tmp to the mission file and close
    $desiredFile.Write($mission_tmp -join "`r`n")
    $desiredFile.Flush()
    $desiredFile.Close()

    # Write the changes and close the zip file
    $fileZip.Dispose()

}
