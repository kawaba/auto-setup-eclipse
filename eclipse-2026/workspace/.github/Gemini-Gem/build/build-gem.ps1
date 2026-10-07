# build-gem.ps1
# GitHub Copilot 版の規約（SpringBoot/GitHub-Copilot）から、Gemini Gem のナレッジ3ファイルを作る。
#
# 使い方（SpringBoot/Gemini-Gem/build フォルダーで）:
#   powershell -ExecutionPolicy Bypass -File build-gem.ps1
#
# 出力（SpringBoot/Gemini-Gem フォルダー）:
#   ガイドライン-共通.txt       ← copilot-instructions.md ＋ spd-core.instructions.md
#   ガイドライン-SpringBoot.txt ← springboot-java.instructions.md
#   ガイドライン-Thymeleaf.txt  ← thymeleaf.instructions.md
#
# 行う変換:
#   - 先頭の applyTo などの設定部分（--- … ---）を取り除く
#   - 管理用の HTML コメント（行頭の <!-- … -->）を取り除く（コードブロックの中と <!--/* は残す）
#   - 「## 更新履歴」以降を取り除く
#   - copilot-instructions.md の冒頭（## 0 より前）と ## 10 を、Gem 用の部品に差し替える
#   - ファイル名の参照を、ナレッジのファイル名に置き換える
#   - 各ファイルの先頭に、Gem 用の見出し（header-*.md）を付ける
#
# このスクリプトは UTF-8（BOM付き）で保存すること（Windows PowerShell 5.1 が日本語を正しく読むため）。

$ErrorActionPreference = 'Stop'

$buildDir = $PSScriptRoot
$gemDir   = Split-Path -Parent $buildDir
$srcDir   = Join-Path (Split-Path -Parent $gemDir) 'GitHub-Copilot'

$utf8    = New-Object System.Text.UTF8Encoding($false)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

function Read-Text([string]$path) {
    return ([IO.File]::ReadAllText($path, $utf8)) -replace "`r`n", "`n"
}

function Write-Text([string]$path, [string]$text) {
    $text = ($text.TrimEnd("`n") + "`n") -replace "`n", "`r`n"
    [IO.File]::WriteAllText($path, $text, $utf8Bom)
}

function Get-Match([string]$text, [string]$pattern, [string]$what) {
    $m = [regex]::Match($text, $pattern, 'Multiline')
    if (-not $m.Success) { throw "版数が見つかりません: $what" }
    return $m.Groups[1].Value
}

# 先頭の --- … --- を取り除く
function Remove-FrontMatter([string]$text) {
    return [regex]::Replace($text, '\A---\n.*?\n---\n', '', 'Singleline')
}

# 行頭から始まる管理用の HTML コメントを取り除く（コードブロックの中、<!--/* は対象外）
function Remove-ManagementComments([string]$text) {
    $out = New-Object System.Collections.Generic.List[string]
    $inFence = $false
    $inComment = $false
    foreach ($line in $text -split "`n") {
        if ($inComment) {
            if ($line -match '-->') { $inComment = $false }
            continue
        }
        if ($line -match '^\s*```') { $inFence = -not $inFence }
        if (-not $inFence -and $line -match '^<!--(?!/\*)') {
            if ($line -notmatch '-->') { $inComment = $true }
            continue
        }
        $out.Add($line)
    }
    return ($out -join "`n")
}

# 「## 更新履歴」以降を取り除く
function Remove-History([string]$text) {
    $i = $text.IndexOf("`n## 更新履歴")
    if ($i -ge 0) { return $text.Substring(0, $i + 1) }
    return $text
}

# 見出し $heading で始まる章を、次の「## 」の直前まで $replacement に差し替える
function Set-Section([string]$text, [string]$heading, [string]$replacement) {
    $start = $text.IndexOf("`n$heading")
    if ($start -lt 0) { throw "章が見つかりません: $heading" }
    $next = $text.IndexOf("`n## ", $start + 1)
    if ($next -lt 0) { $next = $text.Length }
    return $text.Substring(0, $start + 1) + $replacement.TrimEnd("`n") + "`n`n" + $text.Substring($next + 1)
}

# 1つ目の「## 0.」より前（タイトル・適用対象の説明）を取り除く
function Remove-Preamble([string]$text) {
    $i = $text.IndexOf("`n## 0.")
    if ($i -lt 0) { throw '「## 0.」が見つかりません' }
    return $text.Substring($i + 1)
}

# ファイル名の参照をナレッジのファイル名に置き換える（長いものから順に）
function Rename-References([string]$text) {
    $map = [ordered]@{
        '.github/instructions/spd-core.instructions.md'        = 'ガイドライン-共通.txt'
        '.github/instructions/springboot-java.instructions.md' = 'ガイドライン-SpringBoot.txt'
        '.github/instructions/thymeleaf.instructions.md'       = 'ガイドライン-Thymeleaf.txt'
        'instructions/spd-core.instructions.md'                = 'ガイドライン-共通.txt'
        'instructions/springboot-java.instructions.md'         = 'ガイドライン-SpringBoot.txt'
        'instructions/thymeleaf.instructions.md'               = 'ガイドライン-Thymeleaf.txt'
        'spd-core.instructions.md'                             = 'ガイドライン-共通.txt'
        'springboot-java.instructions.md'                      = 'ガイドライン-SpringBoot.txt'
        'thymeleaf.instructions.md'                            = 'ガイドライン-Thymeleaf.txt'
        '.github/copilot-instructions.md'                      = 'ガイドライン-共通.txt'
        'copilot-instructions.md'                              = 'ガイドライン-共通.txt'
    }
    foreach ($k in $map.Keys) { $text = $text.Replace($k, $map[$k]) }
    return $text
}

# Gem では意味をなさない個別の文を置き換える
function Edit-GemSpecific([string]$text) {
    $pairs = @(
        @('- `.github/instructions/` 配下の各ファイルは、対象ファイルを編集するときに追加で適用される（`## 10`）。',
          '- ナレッジの `ガイドライン-SpringBoot.txt`・`ガイドライン-Thymeleaf.txt` は、該当するSPDからコードを生成するときに必ず読む（`## 10`）。'),
        @("> - ``## 0.x``・``最重要ルール``・``実装前チェック`` への参照は、``ガイドライン-共通.txt```n>   の中の節を指す（このファイルには含まれない）。`n", '')
    )
    foreach ($p in $pairs) {
        if (-not $text.Contains($p[0])) { throw "置き換える文が見つかりません: $($p[0].Substring(0, [Math]::Min(40, $p[0].Length)))" }
        $text = $text.Replace($p[0], $p[1])
    }
    return $text
}

# springboot-java の、パッケージ名が無い場合の扱いを Gem 用に置き換える（`## 10.4`）
function Edit-GemSpringBoot([string]$text) {
    $pairs = @(
        @("- **基底パッケージも分からない場合は、そのSPDからコードを生成せず、パッケージ名を尋ねる。**`n  推測でパッケージ名を作ってはならない（1ファイルずつ生成したときに、ファイルごとにパッケージがずれるため）。`n  尋ねるときは、SPDのタイトル行の前に ``※jp.kwebs.<アーティファクト名>.entity`` の形で書くよう案内する。",
          "- **Gem では、SPDにパッケージ名が無い場合は ``package`` 文を書かずに生成する。** 生成を止めて尋ねてはならない。`n  同じプロジェクトのクラスの import とファイルのパスの書き方は、``ガイドライン-共通.txt`` の ``## 10.4``・``## 10.5`` に従う。"),
        @('無い場合に基底パッケージから決め、それも分からないときは生成せずに尋ねたか（`## 20.7`）',
          '無い場合に `package` 文を書かずに生成し、パッケージの分からない同じプロジェクトのクラスの import を推測で書かなかったか（`## 10.4`）')
    )
    foreach ($p in $pairs) {
        if (-not $text.Contains($p[0])) { throw "置き換える文が見つかりません: $($p[0].Substring(0, [Math]::Min(40, $p[0].Length)))" }
        $text = $text.Replace($p[0], $p[1])
    }
    return $text
}

function Expand-Header([string]$name, [hashtable]$vars) {
    $h = Read-Text (Join-Path $buildDir $name)
    foreach ($k in $vars.Keys) { $h = $h.Replace("{{$k}}", $vars[$k]) }
    return $h
}

# ---- 読み込みと版数 ----
$common     = Read-Text (Join-Path $srcDir 'copilot-instructions.md')
$core       = Read-Text (Join-Path $srcDir 'instructions/spd-core.instructions.md')
$springboot = Read-Text (Join-Path $srcDir 'instructions/springboot-java.instructions.md')
$thymeleaf  = Read-Text (Join-Path $srcDir 'instructions/thymeleaf.instructions.md')

$vars = @{
    COMMON     = Get-Match $common     '^\| (\d+\.\d+\.\d+) \|'           'copilot-instructions.md'
    CORE       = Get-Match $core       'SPD-CORE v(\d+\.\d+\.\d+)'        'spd-core'
    SPRINGBOOT = Get-Match $springboot 'SPRINGBOOT-JAVA v(\d+\.\d+\.\d+)' 'springboot-java'
    THYMELEAF  = Get-Match $thymeleaf  'THYMELEAF v(\d+\.\d+\.\d+)'       'thymeleaf'
}

# ---- ガイドライン-共通.txt ----
$c = Remove-History (Remove-ManagementComments $common)
$c = Remove-Preamble $c
$c = Set-Section $c '## 10.' (Read-Text (Join-Path $buildDir 'section10-gem.md'))
$k = Remove-ManagementComments (Remove-FrontMatter $core)
$c = $c.TrimEnd("`n") + "`n`n" + $k.TrimStart("`n")
$c = (Expand-Header 'header-common.md' $vars) + (Edit-GemSpecific (Rename-References $c))
Write-Text (Join-Path $gemDir 'ガイドライン-共通.txt') $c

# ---- ガイドライン-SpringBoot.txt ----
$s = Remove-History (Remove-ManagementComments (Remove-FrontMatter $springboot))
$s = (Expand-Header 'header-springboot.md' $vars) + (Edit-GemSpringBoot (Rename-References $s.TrimStart("`n")))
Write-Text (Join-Path $gemDir 'ガイドライン-SpringBoot.txt') $s

# ---- ガイドライン-Thymeleaf.txt ----
$t = Remove-History (Remove-ManagementComments (Remove-FrontMatter $thymeleaf))
$t = (Expand-Header 'header-thymeleaf.md' $vars) + (Rename-References $t.TrimStart("`n"))
Write-Text (Join-Path $gemDir 'ガイドライン-Thymeleaf.txt') $t

# ---- カスタム指示.md ----
# custom-template.md の {{SECTION:<元>:<見出し>}} を、元の規約のその節で置き換える
function Get-SectionText([string]$text, [string]$heading) {
    $lines = $text -split "`n"
    $level = ($heading -split ' ')[0].Length
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith("$heading ")) { $start = $i; break }
    }
    if ($start -lt 0) { throw "節が見つかりません: $heading" }
    $inFence = $false
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*```') { $inFence = -not $inFence }
        if ($inFence) { continue }
        if ($lines[$i] -match '^(#+) ' -and $Matches[1].Length -le $level) { $end = $i; break }
    }
    $body = ($lines[$start..($end - 1)] -join "`n").TrimEnd()
    $body = [regex]::Replace($body, '(\n---\s*)+\z', '')
    return (Rename-References $body)
}

$sources = @{
    core       = Remove-ManagementComments (Remove-FrontMatter $core)
    springboot = Edit-GemSpringBoot (Remove-ManagementComments (Remove-FrontMatter $springboot))
    thymeleaf  = Remove-ManagementComments (Remove-FrontMatter $thymeleaf)
}
$ci = Expand-Header 'custom-template.md' $vars
$ci = [regex]::Replace($ci, '\{\{SECTION:(\w+):([^}]+)\}\}', {
    param($m)
    Get-SectionText $sources[$m.Groups[1].Value] $m.Groups[2].Value
})
Write-Text (Join-Path $gemDir 'カスタム指示.md') $ci

$pasted = [regex]::Replace($ci, '\A<!--.*?-->\s*', '', 'Singleline')
Write-Host ("カスタム指示.md：貼り付ける部分は {0} 文字" -f $pasted.Length)

Write-Host ("作成しました: 共通 v{0}（SPD-CORE v{1}）/ SpringBoot v{2} / Thymeleaf v{3}" -f `
    $vars.COMMON, $vars.CORE, $vars.SPRINGBOOT, $vars.THYMELEAF)
