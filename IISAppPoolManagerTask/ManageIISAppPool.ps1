[CmdletBinding()]
param ()

Trace-VstsEnteringInvocation $MyInvocation
# Get inputs directly from environment variables
$iisPoolName = $env:iisPoolName
$serverName = $env:serverName
$username = $env:username
$password = $env:password
$action = $env:action

Write-Host "Starting IIS App Pool Manager Task..."
Write-Host "Action: $action"
Write-Host "IIS Pool: $iisPoolName"
Write-Host "Server: $serverName"

# Convert the script parameters
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

try {
    # Creating script block to execute remotely
    $scriptBlock = {
        param(
            [string]$iisPoolName,
            [string]$action
        )
        
        # Import the WebAdministration module
        Import-Module WebAdministration -ErrorAction Stop
        
        # Execute action based on parameter
        switch ($action) {
            "Start" {
                Write-Output "Starting Web Application Pool '$iisPoolName'..."
                Start-WebAppPool -Name $iisPoolName -ErrorAction Stop
                Write-Output "Web Application Pool '$iisPoolName' started successfully."
            }
            "Recycle" {
                Write-Output "Recycling Web Application Pool '$iisPoolName'..."
                Restart-WebAppPool -Name $iisPoolName -ErrorAction Stop
                Write-Output "Web Application Pool '$iisPoolName' recycled successfully."
            }
            "Stop" {
                Write-Output "Stopping Web Application Pool '$iisPoolName'..."
                Stop-WebAppPool -Name $iisPoolName -ErrorAction Stop
                Write-Output "Web Application Pool '$iisPoolName' stopped successfully."
            }
            "ForceStop" {
                Write-Output "Force stopping Web Application Pool '$iisPoolName'..."
                $pool = Get-Item "IIS:\AppPools\$iisPoolName" -ErrorAction SilentlyContinue
                if ($pool -and $pool.State -eq 'Started') {
                    Stop-WebAppPool -Name $iisPoolName -ErrorAction Stop
                    Write-Output "Web Application Pool '$iisPoolName' stopped successfully."
                } else {
                    Write-Output "Web Application Pool '$iisPoolName' is already stopped or does not exist."
                }
                
                Start-Sleep 3
                
                $w3wpProcesses = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "w3wp.exe" -and $_.CommandLine -match "$iisPoolName" }
                if (-not [string]::IsNullOrWhiteSpace($w3wpProcesses)) {
                    foreach ($process in $w3wpProcesses) {
                        Write-Output "Killing process ID: $($process.ProcessId)"
                        Stop-Process -Id $process.ProcessId -Force
                    }
                    Write-Output "Remaining w3wp processes for '$iisPoolName' have been forcibly terminated."
                } else {
                    Write-Output "No remaining w3wp processes found for '$iisPoolName'."
                }
            }
            default {
                throw "Invalid action: $action. Valid options are Start, Stop, Recycle, and ForceStop."
            }
        }
    }

    # Execute the remote command
    Write-Host "Connecting to remote server $serverName..."
    $result = Invoke-Command -ComputerName $serverName -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $iisPoolName, $action -ErrorAction Stop
    
    # Output the result
    $result | ForEach-Object { Write-Host $_ }
    
    Write-Host "IIS App Pool Manager task completed successfully."
    exit 0
    
} catch {
    Write-Host "##vso[task.logissue type=error]$_"
    Write-Error "Error executing IIS App Pool Manager task: $_"
    exit 1
}
