$env:PICO8_DIR = "$env:APPDATA\pico-8\carts"

$workspaces = @{
    projects = "~\projects"
    pico8 = "$env:PICO8_DIR"
}
$ws = $workspaces

# # Delete default powershell aliases that conflict with bash commands
function Remove-AliasSafe($name) { if (Test-Path alias:$name) { Remove-Item -force alias:$name } }

if (get-command git) {
    Remove-AliasSafe "cat"
    Remove-AliasSafe "clear"
    Remove-AliasSafe "cp"
    Remove-AliasSafe "diff"
    Remove-AliasSafe "echo"
    Remove-AliasSafe "kill"
    Remove-AliasSafe "ls"
    Remove-AliasSafe "mv"
    Remove-AliasSafe "ps"
    Remove-AliasSafe "pwd"
    Remove-AliasSafe "rm"
    Remove-AliasSafe "sleep"
    Remove-AliasSafe "tee"
}

Set-Alias subl 'C:\Program Files\Sublime Text 3\sublime_text.exe'
Set-Alias gs Get-GitStatus

Set-Alias cdcmd Set-LocationCommand

Set-Alias pud Push-Location
Set-Alias pod Pop-Location
Set-Alias loc Get-CurrentLocation

# Using rm that comes from Git\usr\bin so don't need to do this but bring back if unix rm otherwise not available and you want -rf to work
# Set-Alias rm Remove-ItemProxy -force -option 'Constant','AllScope'

# swap autocomplete behavior of tab and ctrl+space
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord Ctrl+spacebar -Function Complete

#Import-Module posh-git
Invoke-Expression (&starship init powershell)

# Utility functions

function Get-GitStatus() { git status }
function Get-CurrentLocation() { $PWD.Path }

function Set-LocationCommand() {
    [CmdletBinding(DefaultParameterSetName = 'Command')]
    param(
        [Parameter(ParameterSetName = 'Command', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]
        ${Command}
    )
    Get-Command $Command | Select-Object -ExpandProperty Source | Split-Path | Set-Location
}

function Enable-VCEnv($version) {
    $vc_version = "-latest"
    if ($version -eq "2022") {
        $vc_version = "-version 17"
    }
    elseif ($version -eq "2019") {
        $vc_version = "-version 16"
    }
    elseif ($version -eq "2017") {
        $vc_version = "-version 15"
    }

    $vswhere_path = "vswhere.exe"

    if (!(Get-Command $vswhere_path -ErrorAction SilentlyContinue)) {
        # Try to find vswhere in visual studio install location
        $vswhere_path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (!(Test-Path -LiteralPath $vswhere_path -PathType Leaf)) {
            # Try to find in chocolatey install location
            $vswhere_path = "${env:ProgramData}\chocolatey\lib\vswhere\tools\vswhere.exe"
        }
        if (!(Test-Path -LiteralPath $vswhere_path -PathType Leaf)) {
            # Give up
            Write-Output "Unable to find vswhere.exe"
            exit
        }
    }

    Write-Output "Using vswhere.exe located at ""$vswhere_path"""

    $vswhere_path = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    $vswhere_cmd = "& ""$vswhere_path"" {0} -property installationPath" -f $vc_version

    Write-Host $vswhere_cmd
    $vswhere_result = Invoke-Expression $vswhere_cmd

    if ($vswhere_result -is [array]) {
        $vswhere_result = $vswhere_result[0]
    }

    Write-Host $vc_version
    Write-Host $vswhere_result

    $vcvarsall_path = """{0}\VC\Auxiliary\Build\vcvarsall.bat""" -f $vswhere_result

    cmd /c "$vcvarsall_path amd64&set" |
    ForEach-Object {
        if ($_ -match "=") {
            $v = $_.split("=")
            set-item -force -path "ENV:\$($v[0])" -value "$($v[1])"
        }
        Write-Host $_
    }
}

function Remove-ItemProxy() {
    [CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess = $true, ConfirmImpact = 'Medium', SupportsTransactions = $true, HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113373')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'LiteralPath', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath')]
        [string[]]
        ${LiteralPath},

        [string]
        ${Filter},

        [string[]]
        ${Include},

        [string[]]
        ${Exclude},

        [switch]
        ${Recurse},

        [switch]
        ${Force},

        [Alias('RF')]
        [switch]
        $RecurseForce,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential})


    dynamicparam {
        try {
            $PSBoundParameters.Remove('RecurseForce') | Out-Null
            $targetCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Remove-Item', [System.Management.Automation.CommandTypes]::Cmdlet, $PSBoundParameters)
            $dynamicParams = @($targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
            if ($dynamicParams.Length -gt 0) {
                $paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
                foreach ($param in $dynamicParams) {
                    $param = $param.Value

                    if (-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name)) {
                        $dynParam = [Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
                        $paramDictionary.Add($param.Name, $dynParam)
                    }
                }
                return $paramDictionary
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    begin {
        try {
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Remove-Item', [System.Management.Automation.CommandTypes]::Cmdlet)
            if ($RecurseForce) {
                $scriptCmd = { & $wrappedCmd @PSBoundParameters -Recurse -Force }
            }
            else {
                $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    <#

.ForwardHelpTargetName Microsoft.PowerShell.Management\Remove-Item
.ForwardHelpCategory Cmdlet

#>
}
