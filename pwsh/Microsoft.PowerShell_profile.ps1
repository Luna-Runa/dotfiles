$env:EZA_CONFIG_DIR = "$env:USERPROFILE\.config\eza"
function ls { eza --icons $args }
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ll { eza -la --icons $args }

Set-Alias -Name c -Value claude
Set-Alias -Name vim -Value lvim
Set-Alias -Name grep -Value findstr

# 탭 메뉴 리스트 표시(임시)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# 탭 메뉴 리스트 출력
Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function Complete
# 히스토리 검색 (방향키로 과거 명령 검색), cd 업다운 등등..
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' `
                -PSReadlineChordReverseHistory 'Ctrl+r' `
                -PSReadlineChordSetLocation 'Alt+c' 

oh-my-posh init pwsh --config ~/ps_theme.json | Invoke-Expression

# cd - 기능: 이전 디렉토리로 이동
$global:LastDir = $PWD
Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue
function cd {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Path)
    if ($Path -eq '-') {
        $tmp = $PWD
        Set-Location $global:LastDir
        $global:LastDir = $tmp
    } else {
        $global:LastDir = $PWD
        #if ($Path) { Set-Location @Path } else { Set-Location ~ }
        Set-Location @Path
    }
}

Set-Alias lvim '~/.local/bin/lvim.ps1'

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function settings {
    # 소스 파일 경로 (~/workspace/.vscode/settings.json)
    $source = [System.IO.Path]::Combine($HOME, "workspace", ".vscode", "settings.json")
    
    # 대상 파일 경로 (현재 폴더/.vscode/settings.json)
    $targetDir = Join-Path $PWD ".vscode"
    $target = Join-Path $targetDir "settings.json"
    $backup = Join-Path $targetDir "settings-org.json"
    
    # 소스 파일 존재 확인
    if (-not (Test-Path $source)) {
        Write-Error "소스 파일이 존재하지 않습니다: $source" -Category ObjectNotFound
        return
    }
    
    # 대상 디렉토리 생성 (없는 경우)
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "대상 디렉토리 생성: $targetDir" -ForegroundColor Green
    }
    
    # 기존 대상 파일이 있으면 settings-org.json으로 백업
    if (Test-Path $target) {
        # 이미 백업이 존재하면 덮어쓰기
        if (Test-Path $backup) {
            Remove-Item $backup -Force
        }
        Rename-Item $target $backup -Force
        Write-Host "기존 파일 백업: $target -> $backup" -ForegroundColor Yellow
    }
    
    # fsutil을 사용한 하드링크 생성
    $result = & fsutil hardlink create "$target" "$source" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "하드링크 생성 완료: $target -> $source" -ForegroundColor Green
    } else {
        Write-Error "하드링크 생성 실패: $result"
        # 실패시 백업 복원
        if (Test-Path $backup) {
            Rename-Item $backup $target -Force
            Write-Host "백업 복원: $backup -> $target" -ForegroundColor Red
        }
    }
}

