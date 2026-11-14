# Powershell's configurations
$EDITOR = "nvim"

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -MaximumHistoryCount 1000
Set-PSReadLineOption -predictionsource None
Set-PSReadLineKeyHandler -chord Ctrl+w -function BackwardKillWord
Set-PSReadlineKeyHandler -chord Ctrl+u -function BackwardKillLine

# Unix like Aliases
set-alias -name grep -value select-string
set-alias -name touch -value new-item
function CDEZA { & lez --color=auto --icons=auto --no-system ${args} }
function CDLL { & lez --color=auto --icons=auto --no-system -l ${args} }
function CDLA { & lez --color=auto --icons=auto --no-system -a ${args} }
function CDLLA { & lez --color=auto --icons=auto --no-system -la ${args} }
set-alias -name ls -value CDEZA
set-alias -name ll -value CDLL
set-alias -name la -value CDLA
set-alias -name lla -value CDLLA

# Aliases
function Startupcmd {cd "$env:USERPROFILE/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/"; explorer .}
function Initcmd {nvim $env:USERPROFILE/AppData/Local/nvim/init.lua}
function Alacrittycmd {nvim $env:USERPROFILE/AppData/Roaming/alacritty/alacritty.toml}
function Terminalcmd {nvim "$env:USERPROFILE/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"}
function HostsCmd {nvim "C:\Windows\System32\drivers\etc\hosts"}
function Fetches {cls; bunnyfetch}
$mojang = "$env:APPDATA\Minecraft Bedrock\Users\Shared\games\com.mojang"
function comMojang   { cd $mojang }
function behaviorCmd { cd "$mojang\development_behavior_packs" }
function resourceCmd { cd "$mojang\development_resource_packs" }
function repoCmd {cd "$env:USERPROFILE\Repositories" }

set-alias -name vi -value $EDITOR
set-alias -name init.lua -value Initcmd
set-alias -name alacritty.toml -value Alacrittycmd
set-alias -name settings.json -value Terminalcmd
set-alias -name com.mojang -value comMojang
set-alias -name autostart -value taskschd.msc
set-alias -name shell:startup -value Startupcmd
set-alias -name bf -value bunnyfetch
set-alias -name bfs -value Fetches
set-alias -name hosts -value HostsCmd
set-alias -name repo -value repoCmd
set-alias -name develop -value comMojang
set-alias -name resource -value resourceCmd
set-alias -name behavior -value behaviorCmd

set-alias -name yz -value y
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -path $tmp -encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        set-location -literalpath (Resolve-path -literalpath $cwd).Path
    }
    remove-item -path $tmp
}

function pascal {
	param($file)
	$base = [System.IO.Path]::GetFileNameWithoutExtension($file)
	$tempPath = $env:TEMP

	get-childitem "$tempPath\$base" -erroraction silentlycontinue | remove-item -force -erroraction silentlycontinue
	fpc -Mtp -FE"$env:TEMP" -FU"$env:TEMP" -Fo"$env:TEMP" $file | out-null
	if ($LASTEXITCODE -ne 0) {
		write-host "Compilation Failed."
		return
	}

	& "$env:TEMP\$base.exe"
}

# Prompt
$esc = [char]27

# --- Mode indicator: ":" + bar cursor in insert, ">" + block cursor in command ---
$global:ViModeStr = ':'
$global:ViRedraw  = $false

Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
    param($mode)
    if ($mode -eq 'Command') { $global:ViModeStr = '>'; $seq = "$esc[2 q" }
    else                     { $global:ViModeStr = ':'; $seq = "$esc[6 q" }
    [Console]::Out.Write($seq)
    [Console]::Out.Flush()
    $global:ViRedraw = $true
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# Ctrl+L: run `clear` as a real command (so it lands in history and the prompt knows about it)
$clearHandler = {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('clear')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
Set-PSReadLineKeyHandler -Chord Ctrl+l -ScriptBlock $clearHandler
Set-PSReadLineKeyHandler -Chord Ctrl+l -ViMode Command -ScriptBlock $clearHandler
Set-PSReadLineKeyHandler -Chord Ctrl+l -ViMode Insert  -ScriptBlock $clearHandler

function Test-GitRepo {
    $d = $PWD.ProviderPath
    while ($d) {
        if ([IO.Directory]::Exists("$d\.git") -or [IO.File]::Exists("$d\.git")) { return $true }
        $d = [IO.Path]::GetDirectoryName($d)
    }
    $false
}

function Get-GitInfo {
    $info = @{ Branch = ''; Un = 0; Nc = 0; Sc = 0; Ahead = 0 }
    if (-not (Test-GitRepo)) { return $info }
    $lines = git --no-optional-locks status --porcelain=v2 --branch 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) { return $info }

    foreach ($l in $lines) {
        switch -Regex ($l) {
            '^# branch\.head (.+)'    { if ($Matches[1] -ne '(detached)') { $info.Branch = $Matches[1] } }
            '^# branch\.ab \+(\d+)'   { $info.Ahead = [int]$Matches[1] }
            '^\? '                    { $info.Un++ }
            '^[12u] (.)(.)'           {
                if ($Matches[1] -ne '.') { $info.Sc++ }   # staged
                if ($Matches[2] -ne '.') { $info.Nc++ }   # unstaged
            }
        }
    }
    $info
}

function Get-CwdString($branch) {
    $current = (Get-Location).Path
    if ($current.StartsWith($HOME)) { $current = '~' + $current.Substring($HOME.Length) }
    $current = $current -replace '\\', '/'

    $i = $current.LastIndexOf('/')
    if ($i -ge 0) { $dirPath = $current.Substring(0, $i); $dirName = $current.Substring($i) }
    else          { $dirPath = $current; $dirName = "/$current" }
    if ($dirName -eq '/~') { $dirName = '' }

    if ($branch) { "$esc[2;37m$dirPath$esc[0;33m$dirName" }
    else         { "$esc[2;37m$dirPath$esc[0;37m$dirName" }
}

function prompt {
    if ($global:ViRedraw) {
        $global:ViRedraw = $false
    } else {
        $global:ViModeStr = ':'
        [Console]::Write("$esc[6 q")
        $g = Get-GitInfo

        $last = (Get-History -Count 1 -ErrorAction SilentlyContinue).CommandLine
        $nl   = if ($last -notin 'prompt', 'clear', 'cls', 'reset') { "`n" } else { '' }
        $br   = if ($g.Branch) { "$esc[33m($($g.Branch))" } else { '' }

        $d = ''
        if ($g.Un -gt 0)    { $d += "$esc[34m-add(new) " }
        if ($g.Nc -gt 0)    { $d += "$esc[35m-add(changes) " }
        if ($g.Sc -gt 0)    { $d += "$esc[32m-commit " }
        if ($g.Ahead -gt 0) { $d += "$esc[36m-push " }

        [Console]::Write("$nl$(Get-CwdString $g.Branch) $br $d$esc[00m`n")
    }
    "$($global:ViModeStr) "
}
