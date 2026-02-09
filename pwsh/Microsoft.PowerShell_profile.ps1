Set-Alias -Name c -Value claude
Set-Alias -Name vim -Value nvim
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
        if ($Path) { Set-Location @Path } else { Set-Location ~ }
    }
}
