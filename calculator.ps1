Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
function Play-KeySound { try { [Console]::Beep(720, 25) } catch {} }

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Калькулятор'
$form.ClientSize = New-Object System.Drawing.Size(340, 400)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(57, 61, 63)
$calcIcon = 'C:\Windows\System32\calc.exe'
if (Test-Path -LiteralPath $calcIcon) { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($calcIcon) }

$display = New-Object System.Windows.Forms.TextBox
$display.Location = New-Object System.Drawing.Point(18, 18)
$display.Size = New-Object System.Drawing.Size(304, 72)
$display.Font = New-Object System.Drawing.Font('Segoe UI', 30, [System.Drawing.FontStyle]::Regular)
$display.TextAlign = 'Right'
$display.BackColor = [System.Drawing.Color]::FromArgb(218, 233, 218)
$display.ForeColor = [System.Drawing.Color]::FromArgb(35, 42, 38)
$display.BorderStyle = 'Fixed3D'
$display.ReadOnly = $true
$display.Text = '0'
$form.Controls.Add($display)

$expression = ''
$justCalculated = $false

function Render { $display.Text = if ($expression) { $expression } else { '0' } }
function Append-Value([string]$value) {
  if ($script:justCalculated -and $value -match '[0-9.]') { $script:expression = '' }
  $script:justCalculated = $false
  if ($value -eq '.') {
    $current = ($script:expression -split '[+−×÷]')[-1]
    if ($current.Contains('.')) { return }
    if (!$current) { $script:expression += '0' }
  }
  if ($value -match '^[+−×÷]$') {
    if (!$script:expression -and $value -ne '−') { return }
    if ($script:expression -match '[+−×÷]$') { $script:expression = $script:expression.Substring(0, $script:expression.Length - 1) }
  }
  $script:expression += $value
  Render
}
function Calculate-Result {
  if (!$script:expression -or $script:expression -match '[+−×÷.]$') { return }
  $safe = $script:expression.Replace('×','*').Replace('÷','/').Replace('−','-')
  if ($safe -notmatch '^[0-9+*/(). -]+$') { return }
  try {
    $result = Invoke-Expression $safe
    if ([double]::IsNaN($result) -or [double]::IsInfinity($result)) { throw 'invalid' }
    $script:expression = ([math]::Round([double]$result, 10)).ToString([Globalization.CultureInfo]::InvariantCulture)
    $script:justCalculated = $true
    Render
  } catch { $display.Text = 'Ошибка'; $script:expression = '' }
}

$labels = @('7','8','9','÷','4','5','6','×','1','2','3','−','0','.','+','=')
for ($i = 0; $i -lt $labels.Count; $i++) {
  $button = New-Object System.Windows.Forms.Button
  $button.Text = $labels[$i]
  $button.Font = New-Object System.Drawing.Font('Segoe UI', 16)
  $button.Size = New-Object System.Drawing.Size(72, 54)
  .FlatStyle = 'Flat'
  $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(185, 188, 188)
  $button.BackColor = [System.Drawing.Color]::FromArgb(239, 240, 239)
  $button.ForeColor = [System.Drawing.Color]::FromArgb(35, 37, 38)
  $column = $i % 4; $row = [math]::Floor($i / 4)
  $button.Location = New-Object System.Drawing.Point((18 + $column * 78), (108 + $row * 64))
  $button.Tag = $labels[$i]
  if ($labels[$i] -match '^[÷×−+]$') { $button.BackColor = [System.Drawing.Color]::FromArgb(222, 226, 224); $button.ForeColor = [System.Drawing.Color]::FromArgb(35, 42, 38) }
  if ($labels[$i] -eq '=') { $button.BackColor = [System.Drawing.Color]::FromArgb(241, 157, 42); $button.ForeColor = [System.Drawing.Color]::White; $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(216, 132, 25) }
  $button.Add_Click({
    Play-KeySound
    $value = $this.Tag
    if ($value -eq 'AC') { $script:expression = ''; $script:justCalculated = $false; Render }
    elseif ($value -eq '⌫') { if ($script:expression) { $script:expression = $script:expression.Substring(0, $script:expression.Length - 1) }; Render }
    elseif ($value -eq '%') { $script:expression = [regex]::Replace($script:expression, '(\d+(?:\.\d+)?)$', { param($m) ([double]$m.Value / 100).ToString([Globalization.CultureInfo]::InvariantCulture) }); Render }
    elseif ($value -eq '=') { Calculate-Result }
    else { Append-Value $value }
  })
  $form.Controls.Add($button)
}

$form.Add_KeyDown({
  param($sender, $event)
  $map = @{ '/'='÷'; '*'='×'; '-'='−'; '+'='+'; ','='.'; 'Decimal'='.'; 'Add'='+'; 'Subtract'='−'; 'Multiply'='×'; 'Divide'='÷'; 'Enter'='='; 'Return'='='; '='='='; 'Escape'='AC'; 'Backspace'='⌫'; '%'='%' }
  $key = $event.KeyCode.ToString()
  $value = if ($map.ContainsKey($key)) { $map[$key] } elseif ($key -match '^D[0-9]$') { $key.Substring(1) } elseif ($key -match '^NumPad[0-9]$') { $key.Substring(6) } else { $null }
  if ($value) {
    $event.SuppressKeyPress = $true
    Play-KeySound
    if ($value -eq '=') { Calculate-Result } elseif ($value -eq 'AC') { $script:expression = ''; Render } elseif ($value -eq '⌫') { if ($script:expression) { $script:expression = $script:expression.Substring(0, $script:expression.Length - 1) }; Render } elseif ($value -eq '%') { $script:expression = [regex]::Replace($script:expression, '(\d+(?:\.\d+)?)$', { param($m) ([double]$m.Value / 100).ToString([Globalization.CultureInfo]::InvariantCulture) }); Render } else { Append-Value $value }
  }
})
$form.KeyPreview = $true
[void]$form.ShowDialog()

