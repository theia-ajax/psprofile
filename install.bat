@echo off

mkdir "%USERPROFILE%\.config" 2>NUL

copy wezterm.lua "%USERPROFILE%\.wezterm.lua" 1>NUL
copy starship.toml "%USERPROFILE%\.config\starship.toml" 1>NUL
copy Microsoft.Powershell_profile.ps1 "%USERPROFILE%\Documents\PowerShell\Microsoft.Powershell_profile.ps1" 1>NUL
