Param()

# Get changed Markdown files in index (added or modified)
$files = & git diff --cached --name-only --diff-filter=AM | Where-Object { $_ -match '\.md$' }

foreach ($f in $files) {
  if (-not (Test-Path $f)) { continue }
  $text = Get-Content -Raw -Encoding utf8 -Path $f

  # Convert Obsidian image wikilinks to standard Markdown under /assets/img/
  $text = [Regex]::Replace($text, '!\[\[([^\]]+)\]\]', {
      Param($m)
      $name = $m.Groups[1].Value
      $url = '/assets/img/' + ($name -replace ' ', '%20')
      return "![$name]($url)"
  })

  # Escape pipes inside link text [ ... | ... ](...) to avoid table parsing in kramdown
  $text = [Regex]::Replace($text, '\[([^\]]*\|[^\]]*)\]\(([^)]+)\)', {
      Param($m)
      $inner = ($m.Groups[1].Value -replace '\|', '&#124;')
      $url = $m.Groups[2].Value
      return "[$inner]($url)"
  })

  # Save back as UTF-8 without BOM (important for Jekyll front matter)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Resolve-Path $f), $text, $utf8NoBom)
}
