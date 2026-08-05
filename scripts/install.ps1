# install.ps1 - AnaPPTSkills installer (main logic)
# Pure ASCII. PS 5.1 compatible. No BOM.
#
# Installs setup-anappt and analysis-report-builder into the Trae CN global
# skills directory. Uses mklink /D when the project is a git repo (with UAC
# auto-elevation), otherwise copies the files. Also registers both skills in
# skill-config.json under managedSkills as user_upload.
#
# See ADR 0001 in docs/adr/ for the symlink-vs-junction rationale.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Source,
    [string]$Target,
    [switch]$Cn,
    [switch]$Help
)

# Apply defaults AFTER param block so $PSScriptRoot is populated (PS 5.1 quirk
# when invoked via powershell.exe -File).
if (-not $Source) { $Source = Join-Path $PSScriptRoot '..\skills' }
if (-not $Target) { $Target = Join-Path $env:USERPROFILE '.trae-cn\skills' }

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ----------------------------------------------------------------------------
# Message table (English defaults inline; Chinese loaded from messages.zh.json)
# ----------------------------------------------------------------------------
$msg = New-Object 'System.Collections.Hashtable'

$en = New-Object 'System.Collections.Hashtable'
$en['banner_title']            = 'AnaPPTSkills Installer'
$en['banner_subtitle']         = 'Install setup-anappt and analysis-report-builder into the Trae CN global skills directory.'
$en['step_detect_source']      = '[1/5] Detecting source path and git environment...'
$en['step_source_is_git']      = '[OK] Git repository detected; will use symbolic link (mklink /D) mode.'
$en['step_source_no_git']      = '[OK] No git repository detected; will use copy mode.'
$en['step_source_path']        = '     Source path : {0}'
$en['step_target_path']        = '     Target path : {0}'
$en['step_target_created']     = '[OK] Created target skills directory: {0}'
$en['step_target_exists_link'] = '[WARN] Target is already a link; will remove and recreate: {0}'
$en['step_target_exists_real'] = '[WARN] Target is a real directory; will back up then recreate: {0}'
$en['step_target_backed_up']  = '[OK] Backed up to: {0}'
$en['step_target_not_exists'] = '[OK] Target does not exist; will install fresh: {0}'
$en['step_install']            = '[2/5] Installing Skill: {0}'
$en['step_create_symlink']     = '[OK] Created symbolic link: {0} -> {1}'
$en['step_copy_files']         = '[OK] Copied files: {0} -> {1}'
$en['step_elevating']          = '[INFO] Insufficient privilege; requesting UAC elevation to create the symbolic link...'
$en['step_elevation_declined'] = '[ERROR] User declined UAC elevation; cannot create the symbolic link.'
$en['step_elevation_failed']   = '[ERROR] mklink still failed after elevation. Exit code: {0}'
$en['step_register_config']    = '[3/5] Registering in skill-config.json...'
$en['step_config_missing']     = '[WARN] skill-config.json not found at: {0}'
$en['step_config_skip_hint']   = '[WARN] Skipping registration. Re-run this installer after Trae CN creates the file on first launch.'
$en['step_already_registered'] = '[OK] Already registered (preserving original value): {0} = {1}'
$en['step_newly_registered']   = '[OK] Newly registered: {0} = {1}'
$en['step_config_unchanged']   = '[OK] skill-config.json already up to date; no write needed.'
$en['step_config_written']     = '[OK] Written: {0}'
$en['step_summary']            = '[4/5] Install summary'
$en['step_complete']           = '[5/5] Complete. {0} Skill(s) installed.'
$en['step_backups_header']     = 'Backups produced during this install (please handle manually):'
$en['step_next_steps']         = 'Next step: restart Trae CN (or open a new session); setup-anappt and analysis-report-builder will appear in the Skills list.'
$en['error_source_not_found']  = '[ERROR] Source skills directory does not exist: {0}'
$en['error_target_parent_missing'] = '[ERROR] Target parent does not exist (Trae CN not installed?): {0}'
$en['error_mklink_failed']     = '[ERROR] mklink /D failed. Target: {0}, Source: {1}, Exit code: {2}'
$en['error_config_read']       = '[ERROR] Failed to read skill-config.json: {0}. Error: {1}'
$en['error_config_write']      = '[ERROR] Failed to write skill-config.json: {0}. Error: {1}'
$en['error_unknown_skill_folder'] = '[ERROR] Source has no Skill subfolder with SKILL.md: {0}'
$en['help_usage']              = 'Usage:'
$en['help_options']            = 'Options:'
$en['help_option_source']      = '  -Source <path>    Source skills directory (default: ..\skills relative to script)'
$en['help_option_target']      = '  -Target <path>    Target Trae CN skills directory (default: %USERPROFILE%\.trae-cn\skills)'
$en['help_option_cn']          = '  -Cn               Switch console output to Chinese (default English)'
$en['help_option_whatif']      = '  -WhatIf           Dry run: print actions without performing them'
$en['help_option_help']        = '  -Help             Show this help'
$en['help_example_default']    = 'Example - default install:'
$en['help_example_default_cmd']= '  install.bat'
$en['help_example_cn']         = 'Example - Chinese output:'
$en['help_example_cn_cmd']     = '  install.bat -cn'
$en['help_example_dryrun']     = 'Example - dry run:'
$en['help_example_dryrun_cmd'] = '  install.bat -whatif'

if ($Cn) {
    $msgPath = Join-Path $PSScriptRoot 'messages.zh.json'
    if (-not (Test-Path -LiteralPath $msgPath -PathType Leaf)) {
        Write-Warning "Chinese message file not found: $msgPath. Falling back to English."
        $Cn = $false
    } else {
        try {
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            $null = & cmd /c chcp 65001
        } catch { }
        $json = Get-Content -LiteralPath $msgPath -Encoding UTF8 -Raw | ConvertFrom-Json
        foreach ($p in $json.PSObject.Properties) {
            if ($p.Name -notlike '_*') { $null = $msg.Add($p.Name, $p.Value) }
        }
    }
}
if (-not $Cn) {
    foreach ($k in $en.Keys) { $null = $msg.Add($k, $en[$k]) }
}

function Write-Msg {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [object[]]$FormatArgs
    )
    $template = $msg[$Key]
    if (-not $template) { $template = "[MISSING MESSAGE: $Key]" }
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        $out = $template -f ($FormatArgs -as [array])
    } else {
        $out = $template
    }
    # In -WhatIf mode, action messages prefixed [OK] become [WhatIf] so the
    # user can tell what would have happened vs what actually did.
    if ($WhatIfPreference -and $out.StartsWith('[OK]')) {
        $out = '[WhatIf]' + $out.Substring(4)
    }
    return $out
}

# ----------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------
if ($Help) {
    Write-Host (Write-Msg 'banner_title')
    Write-Host (Write-Msg 'banner_subtitle')
    Write-Host ''
    Write-Host (Write-Msg 'help_usage')
    Write-Host '  install.bat [options]'
    Write-Host '  powershell -ExecutionPolicy Bypass -File install.ps1 [options]'
    Write-Host ''
    Write-Host (Write-Msg 'help_options')
    Write-Host (Write-Msg 'help_option_source')
    Write-Host (Write-Msg 'help_option_target')
    Write-Host (Write-Msg 'help_option_cn')
    Write-Host (Write-Msg 'help_option_whatif')
    Write-Host (Write-Msg 'help_option_help')
    Write-Host ''
    Write-Host (Write-Msg 'help_example_default')
    Write-Host (Write-Msg 'help_example_default_cmd')
    Write-Host (Write-Msg 'help_example_cn')
    Write-Host (Write-Msg 'help_example_cn_cmd')
    Write-Host (Write-Msg 'help_example_dryrun')
    Write-Host (Write-Msg 'help_example_dryrun_cmd')
    exit 0
}

# ----------------------------------------------------------------------------
# Banner
# ----------------------------------------------------------------------------
Write-Host (Write-Msg 'banner_title')
Write-Host (Write-Msg 'banner_subtitle')
Write-Host ''

# ----------------------------------------------------------------------------
# Step 1: Resolve source + detect git
# ----------------------------------------------------------------------------
Write-Host (Write-Msg 'step_detect_source')

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    Write-Host (Write-Msg 'error_source_not_found' @($Source))
    exit 1
}
$sourceResolved = (Resolve-Path -LiteralPath $Source).Path

# Project root = parent of the skills dir (skills lives under <project>\skills)
$projectRoot = Split-Path -Parent $sourceResolved

$useSymlink = $false
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if ($gitExe) {
    $gitOut = & git -C $projectRoot rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitOut -match 'true') {
        $useSymlink = $true
    }
}

if ($useSymlink) {
    Write-Host (Write-Msg 'step_source_is_git')
} else {
    Write-Host (Write-Msg 'step_source_no_git')
}
Write-Host (Write-Msg 'step_source_path' @($sourceResolved))
Write-Host (Write-Msg 'step_target_path' @($Target))
Write-Host ''

# ----------------------------------------------------------------------------
# Verify target parent (Trae CN install root must exist)
# ----------------------------------------------------------------------------
$targetParent = Split-Path -Parent $Target
if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
    Write-Host (Write-Msg 'error_target_parent_missing' @($targetParent))
    exit 1
}

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    if (-not $WhatIfPreference) {
        New-Item -Path $Target -ItemType Directory -Force | Out-Null
    }
    Write-Host (Write-Msg 'step_target_created' @($Target))
    Write-Host ''
}

# ----------------------------------------------------------------------------
# Skill list (folder names must match SKILL.md frontmatter 'name')
# ----------------------------------------------------------------------------
$skillNames = @('setup-anappt', 'analysis-report-builder')

foreach ($name in $skillNames) {
    $skillSrc = Join-Path $sourceResolved $name
    $skillMd  = Join-Path $skillSrc 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
        Write-Host (Write-Msg 'error_unknown_skill_folder' @($skillSrc))
        exit 1
    }
}

# ----------------------------------------------------------------------------
# Step 2: Install each skill (symlink or copy)
# ----------------------------------------------------------------------------
$backups = New-Object System.Collections.ArrayList

foreach ($name in $skillNames) {
    Write-Host (Write-Msg 'step_install' @($name))

    $skillSrc    = Join-Path $sourceResolved $name
    $skillTarget = Join-Path $Target $name

    # Handle existing target
    if (Test-Path -LiteralPath $skillTarget) {
        $item    = Get-Item -LiteralPath $skillTarget -Force -ErrorAction SilentlyContinue
        $isLink  = $false
        if ($item -and $item.LinkType) {
            $lt = [string]$item.LinkType
            if ($lt -eq 'SymbolicLink' -or $lt -eq 'Junction') { $isLink = $true }
        }

        if ($isLink) {
            Write-Host (Write-Msg 'step_target_exists_link' @($skillTarget))
            if (-not $WhatIfPreference) {
                # rmdir removes only the link, never the target contents
                & cmd /c rmdir "`"$skillTarget`""
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "[ERROR] Failed to remove existing link: $skillTarget (exit $LASTEXITCODE)"
                    exit 1
                }
            }
        } else {
            $timestamp  = Get-Date -Format 'yyyyMMddHHmmss'
            $backupName = "$name.bak.$timestamp"
            $backupPath = Join-Path $Target $backupName
            Write-Host (Write-Msg 'step_target_exists_real' @($skillTarget))
            if (-not $WhatIfPreference) {
                Rename-Item -LiteralPath $skillTarget -NewName $backupName -ErrorAction Stop
            }
            Write-Host (Write-Msg 'step_target_backed_up' @($backupPath))
            [void]$backups.Add($backupPath)
        }
    } else {
        Write-Host (Write-Msg 'step_target_not_exists' @($skillTarget))
    }

    # Install
    if ($useSymlink) {
        # Try mklink /D directly first (works if user is admin or has Developer Mode)
        $exitCode = 0
        if (-not $WhatIfPreference) {
            $mklinkCmd = 'mklink /D "' + $skillTarget + '" "' + $skillSrc + '"'
            $mklinkOut = & cmd /c $mklinkCmd 2>&1
            $exitCode  = $LASTEXITCODE
        }

        if ($exitCode -ne 0) {
            Write-Host (Write-Msg 'step_elevating')
            if (-not $WhatIfPreference) {
                $argString = '/c mklink /D "' + $skillTarget + '" "' + $skillSrc + '"'
                try {
                    $proc = Start-Process -FilePath cmd.exe `
                                           -ArgumentList $argString `
                                           -Verb RunAs `
                                           -Wait `
                                           -PassThru `
                                           -WindowStyle Hidden `
                                           -ErrorAction Stop
                    $exitCode = $proc.ExitCode
                } catch {
                    Write-Host (Write-Msg 'step_elevation_declined')
                    exit 1
                }
                if ($exitCode -ne 0) {
                    Write-Host (Write-Msg 'step_elevation_failed' @($exitCode))
                    Write-Host (Write-Msg 'error_mklink_failed' @($skillTarget, $skillSrc, $exitCode))
                    exit 1
                }
            }
        }

        Write-Host (Write-Msg 'step_create_symlink' @($skillTarget, $skillSrc))
    } else {
        if (-not $WhatIfPreference) {
            Copy-Item -LiteralPath $skillSrc -Destination $skillTarget -Recurse -Force -ErrorAction Stop
        }
        Write-Host (Write-Msg 'step_copy_files' @($skillTarget, $skillSrc))
    }
    Write-Host ''
}

# ----------------------------------------------------------------------------
# Step 3: Register in skill-config.json
# ----------------------------------------------------------------------------
Write-Host (Write-Msg 'step_register_config')

$configPath = Join-Path $env:USERPROFILE '.trae-cn\skill-config.json'
$configChanged = $false

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Host (Write-Msg 'step_config_missing' @($configPath))
    Write-Host (Write-Msg 'step_config_skip_hint')
} else {
    try {
        $raw    = Get-Content -LiteralPath $configPath -Raw -ErrorAction Stop
        $config = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host (Write-Msg 'error_config_read' @($configPath, $_.Exception.Message))
        exit 1
    }

    if (-not $config.managedSkills) {
        $config | Add-Member -MemberType NoteProperty -Name 'managedSkills' -Value (New-Object PSObject)
    }

    foreach ($name in $skillNames) {
        $existing = $null
        try { $existing = $config.managedSkills.$name } catch { }
        if ($existing) {
            Write-Host (Write-Msg 'step_already_registered' @($name, $existing))
        } else {
            $config.managedSkills | Add-Member -MemberType NoteProperty -Name $name -Value 'user_upload'
            Write-Host (Write-Msg 'step_newly_registered' @($name, 'user_upload'))
            $configChanged = $true
        }
    }

    if ($configChanged) {
        if (-not $WhatIfPreference) {
            $tempPath = "$configPath.tmp.$PID"
            try {
                $json = $config | ConvertTo-Json -Depth 32
                $json | Set-Content -LiteralPath $tempPath -Encoding UTF8 -ErrorAction Stop
                Move-Item -LiteralPath $tempPath -Destination $configPath -Force -ErrorAction Stop
            } catch {
                Write-Host (Write-Msg 'error_config_write' @($configPath, $_.Exception.Message))
                if (Test-Path $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
                exit 1
            }
        }
        Write-Host (Write-Msg 'step_config_written' @($configPath))
    } else {
        Write-Host (Write-Msg 'step_config_unchanged')
    }
}
Write-Host ''

# ----------------------------------------------------------------------------
# Step 4-5: Summary
# ----------------------------------------------------------------------------
Write-Host (Write-Msg 'step_summary')
Write-Host (Write-Msg 'step_complete' @($skillNames.Count))
if ($backups.Count -gt 0) {
    Write-Host (Write-Msg 'step_backups_header')
    foreach ($b in $backups) { Write-Host "  - $b" }
}
Write-Host ''
Write-Host (Write-Msg 'step_next_steps')

exit 0
