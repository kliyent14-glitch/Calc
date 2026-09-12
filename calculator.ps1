Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Play-KeySound {
  try { [Console]::Beep(720, 20) } catch {}
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Calculator'
$form.ClientSize = New-Object System.Drawing.Size(360, 520)
$form.MinimumSize = New-Object System.Drawing.Size(376, 559)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(42, 45, 48)

$calcIcon = 'C:\Windows\System32\calc.exe'
if (Test-Path -LiteralPath $calcIcon) {
  $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($calcIcon)
}

$history = New-Object System.Windows.Forms.Label
$history.Location = New-Object System.Drawing.Point(18, 18)
$history.Size = New-Object System.Drawing.Size(324, 26)
$history.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Regular)
$history.TextAlign = 'MiddleRight'
$history.ForeColor = [System.Drawing.Color]::FromArgb(170, 178, 186)
$history.Text = ''
$form.Controls.Add($history)

$display = New-Object System.Windows.Forms.TextBox
$display.Location = New-Object System.Drawing.Point(18, 48)
$display.Size = New-Object System.Drawing.Size(324, 68)
$display.Font = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Regular)
$display.TextAlign = 'Right'
$display.BackColor = [System.Drawing.Color]::FromArgb(231, 239, 232)
$display.ForeColor = [System.Drawing.Color]::FromArgb(28, 34, 31)
$display.BorderStyle = 'FixedSingle'
$display.ReadOnly = $true
$display.Text = '0'
$form.Controls.Add($display)

$expression = ''
$justCalculated = $false

function Render {
  if ($script:expression) {
    $display.Text = $script:expression
  } else {
    $display.Text = '0'
  }
}

function Is-Operator([string]$value) {
  return $value -match '^[+\-*/]$'
}

function Current-Number {
  return ($script:expression -split '[+\-*/]')[-1]
}

function Append-Value([string]$value) {
  if ($script:justCalculated -and $value -match '^[0-9.]$') {
    $script:expression = ''
    $history.Text = ''
  }

  $script:justCalculated = $false

  if ($value -eq '.') {
    $current = Current-Number
    if ($current.Contains('.')) { return }
    if (!$current) { $script:expression += '0' }
  }

  if (Is-Operator $value) {
    if (!$script:expression -and $value -ne '-') { return }
    if ($script:expression -match '[+\-*/]$') {
      $script:expression = $script:expression.Substring(0, $script:expression.Length - 1)
    }
  }

  if ($script:expression -eq '0' -and $value -match '^[0-9]$') {
    $script:expression = $value
  } else {
    $script:expression += $value
  }

  Render
}

function Clear-All {
  $script:expression = ''
  $script:justCalculated = $false
  $history.Text = ''
  Render
}

function Backspace {
  if ($script:justCalculated) {
    Clear-All
    return
  }

  if ($script:expression) {
    $script:expression = $script:expression.Substring(0, $script:expression.Length - 1)
  }
  Render
}

function Apply-Percent {
  if (!$script:expression) { return }

  $script:expression = [regex]::Replace(
    $script:expression,
    '(-?\d+(?:\.\d+)?)$',
    {
      param($match)
      ([double]$match.Value / 100).ToString([Globalization.CultureInfo]::InvariantCulture)
    }
  )
  Render
}

function Toggle-Sign {
  if (!$script:expression) {
    $script:expression = '-'
    Render
    return
  }

  $match = [regex]::Match($script:expression, '(-?\d+(?:\.\d+)?)$')
  if (!$match.Success) { return }

  $number = $match.Value
  if ($number.StartsWith('-')) {
    $replacement = $number.Substring(1)
  } else {
    $replacement = '-' + $number
  }

  $script:expression = $script:expression.Substring(0, $match.Index) + $replacement
  Render
}

function Calculate-Result {
  if (!$script:expression -or $script:expression -match '[+\-*/.]$') { return }
  if ($script:expression -notmatch '^[0-9+\-*/(). ]+$') { return }

  try {
    $previous = $script:expression
    $result = Invoke-Expression $script:expression
    if ([double]::IsNaN($result) -or [double]::IsInfinity($result)) { throw 'invalid' }

    $script:expression = ([math]::Round([double]$result, 10)).ToString([Globalization.CultureInfo]::InvariantCulture)
    $history.Text = "$previous ="
    $script:justCalculated = $true
    Render
  } catch {
    $display.Text = 'Error'
    $history.Text = ''
    $script:expression = ''
    $script:justCalculated = $false
  }
}

function Handle-Command([string]$value) {
  Play-KeySound

  switch ($value) {
    'C' { Clear-All; break }
    'Back' { Backspace; break }
    '%' { Apply-Percent; break }
    '+/-' { Toggle-Sign; break }
    '=' { Calculate-Result; break }
    default { Append-Value $value; break }
  }
}

$buttons = @(
  @{ Text='C'; Tag='C'; Type='utility' },
  @{ Text='Back'; Tag='Back'; Type='utility' },
  @{ Text='%'; Tag='%'; Type='utility' },
  @{ Text='/'; Tag='/'; Type='operator' },
  @{ Text='7'; Tag='7'; Type='number' },
  @{ Text='8'; Tag='8'; Type='number' },
  @{ Text='9'; Tag='9'; Type='number' },
  @{ Text='*'; Tag='*'; Type='operator' },
  @{ Text='4'; Tag='4'; Type='number' },
  @{ Text='5'; Tag='5'; Type='number' },
  @{ Text='6'; Tag='6'; Type='number' },
  @{ Text='-'; Tag='-'; Type='operator' },
  @{ Text='1'; Tag='1'; Type='number' },
  @{ Text='2'; Tag='2'; Type='number' },
  @{ Text='3'; Tag='3'; Type='number' },
  @{ Text='+'; Tag='+'; Type='operator' },
  @{ Text='+/-'; Tag='+/-'; Type='utility' },
  @{ Text='0'; Tag='0'; Type='number' },
  @{ Text='.'; Tag='.'; Type='number' },
  @{ Text='='; Tag='='; Type='equals' }
)

for ($i = 0; $i -lt $buttons.Count; $i++) {
  $meta = $buttons[$i]
  $button = New-Object System.Windows.Forms.Button
  $button.Text = $meta.Text
  $button.Tag = $meta.Tag
  $button.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Regular)
  $button.Size = New-Object System.Drawing.Size(75, 60)
  $button.FlatStyle = 'Flat'
  $button.FlatAppearance.BorderSize = 1
  $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(98, 103, 108)
  $button.ForeColor = [System.Drawing.Color]::FromArgb(246, 248, 250)

  if ($meta.Type -eq 'operator') {
    $button.BackColor = [System.Drawing.Color]::FromArgb(84, 91, 99)
  } elseif ($meta.Type -eq 'utility') {
    $button.BackColor = [System.Drawing.Color]::FromArgb(68, 73, 79)
  } elseif ($meta.Type -eq 'equals') {
    $button.BackColor = [System.Drawing.Color]::FromArgb(235, 143, 37)
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(214, 122, 24)
  } else {
    $button.BackColor = [System.Drawing.Color]::FromArgb(56, 61, 67)
  }

  $column = $i % 4
  $row = [math]::Floor($i / 4)
  $button.Location = New-Object System.Drawing.Point((18 + $column * 83), (136 + $row * 70))

  $button.Add_Click({
    Handle-Command ([string]$this.Tag)
  })

  $form.Controls.Add($button)
}

$form.Add_KeyDown({
  param($sender, $event)

  $key = $event.KeyCode.ToString()
  $value = $null

  if ($key -match '^D[0-9]$') { $value = $key.Substring(1) }
  elseif ($key -match '^NumPad[0-9]$') { $value = $key.Substring(6) }
  elseif ($key -eq 'Decimal' -or $key -eq 'OemPeriod') { $value = '.' }
  elseif ($key -eq 'Add') { $value = '+' }
  elseif ($key -eq 'Subtract' -or $key -eq 'OemMinus') { $value = '-' }
  elseif ($key -eq 'Multiply') { $value = '*' }
  elseif ($key -eq 'Divide' -or $key -eq 'OemQuestion') { $value = '/' }
  elseif ($key -eq 'Enter' -or $key -eq 'Return') { $value = '=' }
  elseif ($key -eq 'Escape') { $value = 'C' }
  elseif ($key -eq 'Back') { $value = 'Back' }

  if ($value) {
    $event.SuppressKeyPress = $true
    Handle-Command $value
  }
})

$form.KeyPreview = $true
[void]$form.ShowDialog()
