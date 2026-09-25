$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$specs = @(
    @{ File='bike-sharing/day.csv'; Time='dteday'; Target='cnt'; Step=1; Kind='daily' },
    @{ File='sunspots.csv'; Time='time'; Target='value'; Step=(1.0/12); Kind='numeric' },
    @{ File='usmelec.csv'; Time='time'; Target='value'; Step=(1.0/12); Kind='numeric' },
    @{ File='gasoline.csv'; Time='time'; Target='value'; Step=(7.0/365.25); Kind='numeric' },
    @{ File='ETTh1.csv'; Time='date'; Target='OT'; Step=1; Kind='hourly' }
)
$results = foreach ($spec in $specs) {
    $path = Join-Path $PSScriptRoot $spec.File
    $rows = @(Import-Csv -LiteralPath $path)
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $missing = 0; $invalid = 0; $duplicates = 0; $gaps = 0
    $minimum = [double]::PositiveInfinity; $maximum = [double]::NegativeInfinity
    $previous = $null
    foreach ($row in $rows) {
        foreach ($property in $row.PSObject.Properties) {
            if ([string]::IsNullOrWhiteSpace($property.Value) -or $property.Value -match '^(NA|NaN|null|\?)$') { $missing++ }
            if ($property.Name -ne $spec.Time) {
                $number = 0.0
                if (-not [double]::TryParse($property.Value, [System.Globalization.NumberStyles]::Float, $culture, [ref]$number) -or [double]::IsNaN($number) -or [double]::IsInfinity($number)) { $invalid++ }
            }
        }
        $stamp = $row.($spec.Time)
        if (-not $seen.Add($stamp)) { $duplicates++ }
        if ($spec.Kind -eq 'numeric') { $current = [double]::Parse($stamp, $culture) }
        else { $current = [datetime]::Parse($stamp, $culture) }
        if ($null -ne $previous) {
            if ($spec.Kind -eq 'daily') { $difference = ($current - $previous).TotalDays }
            elseif ($spec.Kind -eq 'hourly') { $difference = ($current - $previous).TotalHours }
            else { $difference = $current - $previous }
            if ([math]::Abs($difference - $spec.Step) -gt 0.0000001) { $gaps++ }
        }
        $previous = $current
        $target = [double]::Parse($row.($spec.Target), $culture)
        $minimum = [math]::Min($minimum, $target)
        $maximum = [math]::Max($maximum, $target)
    }
    [pscustomobject]@{
        File=$spec.File; Rows=$rows.Count; Columns=@($rows[0].PSObject.Properties).Count
        Bytes=(Get-Item -LiteralPath $path).Length; Target=$spec.Target
        MissingCells=$missing; InvalidNumericCells=$invalid
        DuplicateTimes=$duplicates; IrregularTimeSteps=$gaps
        FirstTime=$rows[0].($spec.Time); LastTime=$rows[-1].($spec.Time)
        TargetMin=$minimum; TargetMax=$maximum
        SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
}
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'quality_checks.json') -Encoding UTF8
$results | Select-Object File,Rows,Bytes,MissingCells,InvalidNumericCells,DuplicateTimes,IrregularTimeSteps,TargetMin,TargetMax | Format-Table -AutoSize
