# The Azure Inventory Wizard
Provides an Azure Resource Manager Powershell script for collecting Azure Cloud IaaS VM information.

## Requires
1. Windows PowerShell
2. Azure PowerShell Az module
3. Access to Azure subscription(s)
<br/><br/><br/>

## Features
1. Retrieve virtual machine attributes in "csv" format directly from workstation
2. Configurable VM attribute retrieval:
   1.  Retrieve ALL virtual machines across all accessible subscription(s),  csv file per subscription
   2.  Retrieve from defined reference list, scans all subscriptions for referenced item(s)
3. Configurable csv file(s) name prefix
4. Date and subscription stamped output file 
<br/><br/><br/>

## Getting started with Azure PowerShell
https://azure.microsoft.com/en-us/blog/azps-1-0/
<br/>

#### 1. Check PowerShell modules...
*Get-Module -ListAvailable | Select-Object -Property Name,Version,Path*
<br/><br/>

#### 2. Check Az-module version...
*Get-InstalledModule AzureRM | Select-Object -Property Name,Version,Path*
<br/><br/>

#### 3. Install Az-module...
*Install-Module -Name Az -Force -Scope CurrentUser -AllowClobber*
<br/><br/>

#### 4. Log in to Azure from PowerShell...
*Login-AzAccount*
<br/><br/>

#### 5. List Azure subscriptions...
*Get-AzSubscription*
<br/><br/><br/>

## Usage Guidelines
This script should be executed from within the Windows PowerShell Integrated Scripting Environment (ISE)
1. Load the script in PowerShell ISE and update the export file path to the desired storage location
2. Set the script control variables
3. Log in to Azure with
   Login-AzAccount
4. Run the script
5. Consult the PowerShell ISE output for progress
6. Load and consult output CSV file in MS Excel for inventory results
