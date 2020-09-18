#Script    : Get-AzVMDetail_v1.0.0.ps1
#Author    : Nelius N. Dempers $mailto: nelius.dempers@gmail.com
#Purpose   : Script for collecting Microsoft Azure VM details and exporting it to .csv inventory file
#            $Export field list...
#            <AzVMName>, <AzVMCreated>, <AzVMResourceGroup>, <AzVMSubscription>, <AzVMLocation>, <AzVMStatus>, 
#            <AzVMSize>, <AzVMExtensions>, <AzVMAvailabilitySet>, <AzVMFaultDomain>, <AzVMUpdateDomain>, 
#            <AzVMAvailabilityZone>, <AzVMProximityPlacementGroup>, <AzVMTags>, <AzVMOSType>, <AzVMOSSourceImage>, 
#            <AzVMOSDiskInfo>, <AzVMOSDiskName>, <AzVMDataDiskCount>, <AzVMDataDiskInfo>, <AzVMDataDiskNames>, <AzVMNICInfo>
#Copyright : Copyright (c) 2020, Nelius N. Dempers
#            LICENSE: BSD-2-Clause (https://opensource.org/licenses/BSD-2-Clause)
#Syntax    : This script should be executed from within the Windows PowerShell ISE
#            but first...
#            Update the export file path to the desired storage location
#            Manually log in to Azure with ...Login-AzAccount
#            Set script control variables
#            Run the script
#            Consult PowerShell output for progress
#            Consult output CSV file for inventory results
#Notes     : Version number syntax = major.minor.patch
#Requires  : Windows PowerShell,
#            Azure PowerShell Az module,
#            Access to Azure subscription
#
#Change History:
#Ver          Date         Auth  Comments
#v1.00.00     09-Jul-2020  NND   Initial Az-Module version 
#                                ...migrated AzureRM-Module v4.9.0 and added support for PPGs
#
#$created: 09-Jul-2020 $updated: 09-Jul-2020 $released: 09-Jul-2020
$ScriptName = 'Get-AzVMDetail'
$ScriptVersion = 'v1.0.0'
$ExportPath = 'c:\temp'
#Retrieve based on reference VM name list ... set to true and populate desired server name list ...
$RetrieveFromList = $false;
$RefVMNameLst = "server_name_01, server_name_n"
#DebugLevel ...
# 0 - Tracking "Off"
# 1 = Level [1] tracing
# 2 = Level [2] tracing
# 3 = Level [3] tracing
$DebugLevel = 3
#Extend line-wrapping for DebugLevel=3
if ($DebugLevel -eq 3){$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(512,50)}
if (Test-Path -Path $ExportPath){
  $AzureSubscriptions = Get-AzSubscription
  
  foreach ($AzSubscription in $AzureSubscriptions) {
    #Variable clean-up for multi-execution within same login session ...
    $i = 0
    Clear-Variable -name VMo -ErrorAction SilentlyContinue
    Clear-Variable -name NEVMSizeCatalog -ErrorAction SilentlyContinue
    Clear-Variable -name WEVMSizeCatalog -ErrorAction SilentlyContinue
    Clear-Variable -name PROPs -ErrorAction SilentlyContinue
    Clear-Variable -name Results -ErrorAction SilentlyContinue
    
    Select-AzSubscription -SubscriptionName $AzSubscription.Name
    $AzureSubscriptionName = (Get-AzContext).Subscription.Name
    if ($DebugLevel -gt 0){Write-Host "$(Get-Date -Format s) START: Get-AzVMs for subscription $AzureSubscriptionName" -ForegroundColor Blue}
    $VMo = Get-AzVM
    $NEVMSizeCatalog = Get-AzVMSize -Location northeurope
    $WEVMSizeCatalog = Get-AzVMSize -Location westeurope
    if ($DebugLevel -gt 0){Write-Host " .$(Get-Date -Format s) Get-AzVM" -ForegroundColor Gray}
    if ($($VMo).count -gt 0){
      #for test run uncomment below and set test count ...
      #for ($tc=1; $tc -le 10; $tc++){
      if ($RetrieveFromList) {$TotalSrvNum = $RefVMNameLst.split(',').count}else{$TotalSrvNum = $VMo.Count}
      foreach ($VMi in $VMo){
        #Check for $RetrieveFromList ...
        if ($RetrieveFromList) {
          #check if in list
          $ServerFound = $RefVMNameLst -match $VMi.Name
        }else{
          #process complete subscription VM list ...
          $ServerFound = $true
        }
        
        
        if ($ServerFound) {
          #for test run uncomment below to enforce test count ...
          #$VMi = $VMo[$tc]
          $i++
          if ($DebugLevel -gt 0){Write-Host " ..$(Get-Date -Format s) Get-AzVMInfo for $($VMi.Name) ($i of $($TotalSrvNum))" -ForegroundColor Green}
          
          
          Clear-Variable -name Created -ErrorAction SilentlyContinue
          $Created = $VMis.Disks[0].Statuses[0].Time
          if ($Created -eq $null){
            $Created = 'n/a'
          }else{
            $Created = $Created.ToString("yyyy-MM-ddThh:mm:ss")
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.Created" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.Created '$Created'" -ForegroundColor Gray}
          
          
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ResourceGroupName" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ResourceGroupName '$($VMi.ResourceGroupName)'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMSizeInfo -ErrorAction SilentlyContinue
          if ($VMi.location -eq "northeurope"){
                  $VMSizeInfo = $NEVMSizeCatalog | where-object {$_.name -eq "$($VMi.HardwareProfile.VmSize)"}
          }elseif ($VMi.location -eq "westeurope"){
                  $VMSizeInfo = $WEVMSizeCatalog | where-object {$_.name -eq "$($VMi.HardwareProfile.VmSize)"}
          }else{
              $VMSizeInfo = "No matching VMSizeCatalog"
          }
          if ($VMSizeInfo -eq "No matching VMSizeCatalog"){
            $VMSize = 'No matching VMSizeCatalog'
          }else{
            if ($($VMi.HardwareProfile.VmSize) -like "*-*") {
                $s = $VMi.HardwareProfile.VmSize
                $s = [regex]::matches($s,'(?<=-).+?(?=_)').value
                $s = [regex]::matches($s,'\d+').value
                $VMSize = "$($VMi.HardwareProfile.VmSize) ($($s)/$($VMSizeInfo.NumberOfCores) cores, $($VMSizeInfo.MemoryInMB) MB)"
            }else{
                $VMSize = "$($VMi.HardwareProfile.VmSize) ($($VMSizeInfo.NumberOfCores) cores, $($VMSizeInfo.MemoryInMB) MB)"
            }
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.Size" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.Size '$VMSize'" -ForegroundColor Gray}
          
          
          $VMis = Get-AzVM -Name $VMi.Name -ResourceGroup $VMi.ResourceGroupName -Status
          $VMLocation = $VMi.location
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerStatus" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerStatus '$($VMis.Statuses[1].DisplayStatus)'" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerLocation '$VMLocation'" -ForegroundColor Gray}
          $TAGa = $VMi.Tags
          Clear-Variable -name TagList -ErrorAction SilentlyContinue
          if ($TAGa.Count -eq 0){
            $TagList = 'n/a'
          }else{
            $TAGa = $VMi.Tags.GetEnumerator() | Sort-Object -Property key
            foreach ($TAGi in $TAGa){
              $TagList = $TagList+"{Key=$($TAGi.Key); Value=$($TAGi.Value)}, "
            }
            $TagList = $TagList+"}"
            $TagList = $TagList.Replace(", }","")
          } 
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerTags" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerTags '$TagList'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMEXTs -ErrorAction SilentlyContinue
          $VMEXTa = ($VMi.Extensions).Id
          foreach ($VMEXTi in $VMEXTa){
            $VMEXTs += @($VMEXTi.split("/")[-1])
          }
          if ($VMEXTs -eq $null) {$VMEXTs = "n/a"}
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerExtensions" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ServerExtensions '$VMEXTs'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMASi -ErrorAction SilentlyContinue
          Clear-Variable -name VMFDi -ErrorAction SilentlyContinue
          Clear-Variable -name VMUDi -ErrorAction SilentlyContinue
          $VMAS = $VMi.AvailabilitySetReference
          if ($VMAS -eq $null){
            $VMASi = 'n/a'
            $VMFDi = 'n/a'
            $VMUDi = 'n/a'
          }else{
            $VMASi = $VMAS.Id.split('/')[-1]
            #Get-AzFD/UD
            $VMFDi = $VMis.PlatformFaultDomain
            $VMUDi = $VMis.PlatformUpdateDomain
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.AvailabilitySet" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.AvailabilitySet '$VMASi' VMFaultDomain '$VMFDi' VMUpdateDomain '$VMUDi'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMAZi -ErrorAction SilentlyContinue
          $VMAZ = $VMi.Zones
          if ($VMAZ.Count -eq 0){
            $VMAZi = 'n/a'
          }else{
            $VMAZi = $VMAZ -join ', '
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.AvailabilityZone" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.AvailabilityZone '$VMAZi'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMPPGi -ErrorAction SilentlyContinue
          $VMPPG = $VMi.ProximityPlacementGroup
          if ($VMPPG -eq $null){
            $VMPPGi = 'n/a'
          }else{
            $VMPPGi = $VMi.ProximityPlacementGroup.Id.split('/')[-1]
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ProximityPlacementGroup" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.ProximityPlacementGroup '$VMPPGi'" -ForegroundColor Gray}
          
          
          Clear-Variable -name OSSourceImage -ErrorAction SilentlyContinue
          $OSSourceImage = "$($VMi.StorageProfile.ImageReference.Publisher)/$($VMi.StorageProfile.ImageReference.Offer)/$($VMi.StorageProfile.ImageReference.Sku)/$($VMi.StorageProfile.ImageReference.Version)"
          if ($($OSSourceImage.replace("/","")) -eq ""){$OSSourceImage = 'n/a'}
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.OSSourceImage" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.OSSourceImage '$OSSourceImage'" -ForegroundColor Gray}
          
          
          Clear-Variable -name OSManagedDiskType -ErrorAction SilentlyContinue
          $OSManagedDiskType = $VMi.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
          if ($OSManagedDiskType -eq $null){$OSManagedDiskType = 'n/a'}
          
          Clear-Variable -name VMOSDisk -ErrorAction SilentlyContinue
          $VMOSDisk = "{"
          if ($VMis.Statuses[1].DisplayStatus -like "*deallocated") {
            $dd = Get-AzDisk -DiskName $VMi.StorageProfile.OsDisk.Name -ResourceGroupName $VMi.ResourceGroupName -ErrorAction SilentlyContinue
            $VMOSDisk = $VMOSDisk + "Size=$($dd.DiskSizeGB)GB; Type=$($dd.Sku.Name)"
          }else{
            $VMOSDisk = $VMOSDisk + "Size=$($VMi.StorageProfile.OsDisk.DiskSizeGB)GB; Type=$($OSManagedDiskType)"
          }
          $VMOSDisk = $VMOSDisk+"}"
          
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.OSDisk" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.OSDisk '$VMOSDisk'" -ForegroundColor Gray}
          
          
          Clear-Variable -name VMDataDisks -ErrorAction SilentlyContinue
          Clear-Variable -name DataDiskProps -ErrorAction SilentlyContinue
          Clear-Variable -name DataDisks -ErrorAction SilentlyContinue
          $c=0
          for ($c=0; $c -lt $VMi.StorageProfile.DataDisks.Count; $c++){
            if ($VMis.Statuses[1].DisplayStatus -like "*deallocated") {
              $dd = Get-AzDisk -DiskName $VMi.StorageProfile.DataDisks[$c].Name -ResourceGroupName $VMi.ResourceGroupName -ErrorAction SilentlyContinue
              $DataDiskProps = [ordered]@{
                "Lun" = "$($VMi.StorageProfile.DataDisks[$c].Lun)"
                "Size" = "$($dd.DiskSizeGB)GB"
                "Type" = "$($dd.Sku.Name)"
              }
            }else{
              $DataDiskProps = [ordered]@{
                "Lun" = "$($VMi.StorageProfile.DataDisks[$c].Lun)"
                "Size" = "$($VMi.StorageProfile.DataDisks[$c].DiskSizeGB)GB"
                "Type" = "$($VMi.StorageProfile.DataDisks[$c].ManagedDisk.StorageAccountType)"
              }
            }
            $DataDisks += @(New-Object pscustomobject -Property $DataDiskProps)
          }
          
          $SortedDataDisks = $DataDisks | Sort-Object {[int]$_.Lun}
          $DataDiskList = "{"
          foreach ($VMDataDiski in $SortedDataDisks){
            $DataDiskList = $DataDiskList+$VMDataDiski
          }
          $VMDataDisks = $DataDiskList.Replace("@", ", ")
          $VMDataDisks = $VMDataDisks.Replace("{, {", "{")
          
          if ($VMDataDisks -eq "{}"){$VMDataDisks = "n/a"}
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.DataDisks" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.DataDisks '$($VMDataDisks|sort)'" -ForegroundColor Gray}
          
          if ($VMi.StorageProfile.DataDisks.Count -eq 0){$VMDataDiskNames = "n/a"}else{$VMDataDiskNames = $VMi.StorageProfile.DataDisks.Name -join ', '}
          
          
          Clear-Variable -name VMNICs -ErrorAction SilentlyContinue
          $VMNICa = Get-AzNetworkInterface -ResourceGroupName $VMi.ResourceGroupName | where {$_.Id -eq $VMi.NetworkProfile.NetworkInterfaces.Id}
          foreach ($VMNICi in $VMNICa){
            if ($($VMNICa).count -gt 1){
              $VMNICs += $VMNICi.Id.split('/')[-1] + " (AcceleratedNetworkingEnabled=$($VMNICa.EnableAcceleratedNetworking), Primary=$($VMNICi.IpConfigurations.Primary), $($VMNICi.IpConfigurations.PrivateIpAllocationMethod), $($VMNICi.IpConfigurations.PrivateIpAddressVersion) IP=$($VMNICi.IpConfigurations.PrivateIpAddress))" + ', '
            }else{
              $VMNICs += $VMNICi.Id.split('/')[-1] + " (AcceleratedNetworkingEnabled=$($VMNICa.EnableAcceleratedNetworking), Primary=$($VMNICi.IpConfigurations.Primary), $($VMNICi.IpConfigurations.PrivateIpAllocationMethod), $($VMNICi.IpConfigurations.PrivateIpAddressVersion) IP=$($VMNICi.IpConfigurations.PrivateIpAddress))"
            }
          }
          if ($DebugLevel -eq 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.NICs" -ForegroundColor Gray}
          if ($DebugLevel -eq 3){Write-Host " ...$(Get-Date -Format s) Get-AzVM.NICs '$VMNICs'" -ForegroundColor Gray}
          
          
          $PROPs = [ordered]@{
            "AzVMName" = $VMi.Name
            "AzVMCreated" = $Created
            "AzVMResourceGroup" = $VMi.ResourceGroupName
            "AzVMSubscription" = $AzureSubscriptionName
            "AzVMLocation" = $VMLocation
            "AzVMStatus" = $VMis.Statuses[1].DisplayStatus
            "AzVMSize" = $VMSize
            "AzVMExtensions" = $VMEXTs -join ', '
            "AzVMAvailabilitySet" = $VMASi
            "AzVMFaultDomain" = $VMFDi
            "AzVMUpdateDomain" = $VMUDi
            "AzVMAvailabilityZone" = $VMAZi
            "AzVMProximityPlacementGroup" = $VMPPGi
            "AzVMTags" = $TagList
            "AzVMOS" = $VMi.StorageProfile.OsDisk.OsType
            "AzVMOSSourceImage" = $OSSourceImage
            "AzVMOSDiskInfo" = $VMOSDisk
            "AzVMOSDiskName" = $VMi.StorageProfile.OsDisk.Name
            "AzVMDataDiskCount" = "$($VMi.StorageProfile.DataDisks.Count) of $($VMSizeInfo.MaxDataDiskCount)"
            "AzVMDataDiskInfo" = $VMDataDisks
            "AzVMDataDiskNames" = $VMDataDiskNames
            "AzVMNICInfo" = $VMNICs
          }
          $Results += @(New-Object pscustomobject -Property $PROPs) 
          if ($DebugLevel -ge 2){Write-Host " ...$(Get-Date -Format s) Get-AzVM.WriteProperties" -ForegroundColor Gray}
        }
      }
    }else{
      Write-Host "No virtual machines found for subscription $AzureSubscriptionName Azure subscription!!!"
    }
    if ($Results -ne $null){$Results | Export-Csv "$ExportPath\$($ScriptName)_$($ScriptVersion)_$($AzureSubscriptionName)_$(get-date -f yyyy-MM-ddThhmmss).csv" -NoTypeInformation}
    if ($DebugLevel -gt 0){Write-Host "$(Get-Date) END: Get-AzVM ...complete" -ForegroundColor Blue}
  }
}else{
  Write-Host "The defined export file path $ExportPath is not availability, please update the "$ExportPath" definition with a valid path!!!"
}
