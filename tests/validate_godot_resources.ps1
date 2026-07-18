$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "2d-project-assets"
$errors = [System.Collections.Generic.List[string]]::new()

Get-ChildItem -Path $projectRoot -Recurse -File -Filter '*.gd' | ForEach-Object {
    $scriptContent = Get-Content -Raw -LiteralPath $_.FullName
    $physicsFunctions = [regex]::Matches(
        $scriptContent,
        '(?m)^func\s+_physics_process\((?<parameter>[A-Za-z_][A-Za-z0-9_]*):\s*float\)'
    )

    foreach ($physicsFunction in $physicsFunctions) {
        $parameter = $physicsFunction.Groups['parameter'].Value
        $usageCount = [regex]::Matches($scriptContent, "\b$([regex]::Escape($parameter))\b").Count
        if (-not $parameter.StartsWith('_') -and $usageCount -eq 1) {
            $relativeScript = $_.FullName.Substring($repoRoot.Length + 1)
            $errors.Add("Unused physics parameter must start with an underscore: $relativeScript ($parameter)")
        }
    }
}

$mobScript = Get-Content -Raw (Join-Path $projectRoot "mob.gd")
if ($mobScript -notmatch '@onready\s+var\s+player\s*=\s*get_node\("/root/Game/Player"\)') {
    $errors.Add('mob.gd must resolve Player from the absolute scene-tree path /root/Game/Player.')
}
if ($mobScript -notmatch 'direction_to\(player\.global_position\)') {
    $errors.Add('mob.gd must read the Player global_position property when calculating direction.')
}

Get-ChildItem -Path $projectRoot -Recurse -File -Filter '*.import' | ForEach-Object {
    $relativePath = $_.FullName.Substring($repoRoot.Length + 1)
    git -C $repoRoot check-ignore -q -- $relativePath
    if ($LASTEXITCODE -eq 0) {
        $errors.Add("Godot import metadata is ignored: $relativePath")
    }
}

Get-ChildItem -Path $projectRoot -Recurse -File -Include '*.tscn', '*.tres' | ForEach-Object {
    $resourcePath = $_.FullName
    $lineNumber = 0

    Get-Content -LiteralPath $resourcePath | ForEach-Object {
        $lineNumber++
        $resourceMatch = [regex]::Match(
            $_,
            '^\[ext_resource type="(?<type>[^"]+)".*uid="(?<uid>uid://[^"]+)".*path="res://(?<path>[^"]+)"'
        )
        if (-not $resourceMatch.Success) {
            return
        }

        $sourcePath = Join-Path $projectRoot $resourceMatch.Groups['path'].Value
        $importPath = "$sourcePath.import"
        if (-not (Test-Path -LiteralPath $importPath)) {
            if ($resourceMatch.Groups['type'].Value -eq 'Texture2D') {
                $relativeResource = $resourcePath.Substring($repoRoot.Length + 1)
                $errors.Add("Missing texture import metadata in ${relativeResource}:$lineNumber")
            }
            return
        }

        $importContent = Get-Content -Raw -LiteralPath $importPath
        $importMatch = [regex]::Match($importContent, '(?m)^uid="(?<uid>uid://[^"]+)"')
        if (-not $importMatch.Success) {
            $errors.Add("Missing UID in import metadata: $importPath")
            return
        }

        $sceneUid = $resourceMatch.Groups['uid'].Value
        $importUid = $importMatch.Groups['uid'].Value
        if ($sceneUid -ne $importUid) {
            $relativeResource = $resourcePath.Substring($repoRoot.Length + 1)
            $errors.Add("Stale UID in ${relativeResource}:$lineNumber ($sceneUid != $importUid)")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Output "ERROR: $_" }
    exit 1
}

Write-Output 'Godot resource metadata validation passed.'
