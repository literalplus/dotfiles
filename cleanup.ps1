# For $HOME/.gitconfig: (Credit mschreiber)
#[alias]
#    cleanup = "!git branch --merged | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -d"
#    force-cleanup = "!git branch | grep -v '^  master$' | grep -v '^  development$' | grep -v '^* ' | xargs git branch -D"
# NOTE: UNSUPPORTED script as I currently do not use Windows

param (
    [switch]$tomaster = $false,
    [switch]$forcedeleteall = $false
)

if($forcedeleteall) {
    $confirm = Read-Host "Are you sure? This will yeet all branches except master. You will lose all work"
    if ($confirm -ne 'y') {
        Write-Output "Knew it."
        exit
    }
    Write-Output "Your warranty is void beyond this point."
}

function Optimize-CurrentGitRepo([string]$name) {
 $HasGit = Test-Path .git -PathType Container
 if ($HasGit) {
    $BranchName = git rev-parse --abbrev-ref HEAD | Out-String
    $BranchName = $BranchName.replace("`n", "").replace("`r", "")
    Write-Output " ... Processing git repository $_ at branch $BranchName"
    if ($BranchName -ne "master" -And $tomaster) {
        Write-Output " Checking out master"
        git checkout master
    }
    if ($forcedeleteall){
        git force-cleanup
    } else {
        git cleanup
    }
 } else {
     Write-Output " --- Not a git repository: $_"
 }
}

$NonProjects = @(".git", ".idea", "out")
Get-ChildItem . -Directory -Name -Exclude $NonProjects | ForEach-Object {
 Set-Location $_
 Optimize-CurrentGitRepo($_)
 Set-Location ..
}
Optimize-CurrentGitRepo("Grissemann")
