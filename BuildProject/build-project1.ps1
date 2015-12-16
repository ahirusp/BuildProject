# =================================================================
# リポジトリチェックアウトしてoriginからPullした後にMsBuild実行する
# =================================================================

# システム環境設定 ※パスが通っていれば不要のはず
$Env:Path += ";C:\Program Files (x86)\Git\bin"          # git.exe
$Env:Path += ";C:\Program Files (x86)\MSBuild\12.0\Bin" # msbuild.exe

# 準備
$projectName = "project1"

$currentDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$srcDir = [System.IO.Path]::Combine($currentDir, "src")
$projectDir = [System.IO.Path]::Combine($srcDir, $projectName)
$logFilePath = [System.IO.Path]::Combine($projectDir, "BuildLog.txt")

# 選択肢の定義
$questions =
 (("&1:Exit"),("Exit")), 
 (("&2:master"),("master branch")),
 (("&3:refs/tags/mvvm-1"),("tag mvvm-1")),
 (("&4:refs/tags/mvvm-2"),("tag mvvm-2")),
 (("&5:refs/tags/mvvm-3"),("tag mvvm-3"))

# *****************************************************************
# 関数定義
# *****************************************************************
function WriteLog($message)
{
	$time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
	Write-Host ($time + " " + $message)
	Write-Output ($time + " " + $message) | Out-File $logFilePath -Append
}

function ExecuteProcess($fileName,$arguments,$description)
{
	WriteLog ""
	WriteLog "=============================="
	WriteLog "[EXECUTE] $fileName $arguments"

	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = $fileName
	$pinfo.Arguments = $arguments
	$pinfo.RedirectStandardOutput = $true
	$pinfo.RedirectStandardError = $true
	$pinfo.UseShellExecute = $false
	$pinfo.CreateNoWindow = $true

	$proc = New-Object System.Diagnostics.Process
	$proc.StartInfo = $pinfo

	$stdOutBuffer = New-Object System.Text.StringBuilder
	$stdErrBuffer = New-Object System.Text.StringBuilder

	$action = {
		if(![string]::IsNullOrEmpty($EventArgs.Data)){
			$Event.MessageData.AppendLine($EventArgs.Data)
		}
	}

	$stdOutEvent = Register-ObjectEvent -InputObject $proc -Action $action -EventName "OutputDataReceived" -MessageData $stdOutBuffer
	$stdErrEvent = Register-ObjectEvent -InputObject $proc -Action $action -EventName "ErrorDataReceived" -MessageData $stdErrBuffer
	[void]$proc.Start()
	$proc.BeginOutputReadLine()
	$proc.BeginErrorReadLine()
	$proc.WaitForExit()

	Unregister-Event -SourceIdentifier $stdOutEvent.Name
	Unregister-Event -SourceIdentifier $stdErrEvent.Name

	WriteLog "------------------------------"
	WriteLog $stdOutBuffer.ToString()
	WriteLog $stdErrBuffer.ToString()
	WriteLog ("EXITCODE: " + $proc.ExitCode)
	WriteLog "------------------------------"

	if($proc.ExitCode -eq 0){
		WriteLog "[INFO] $description successful."
	}
	else {
		WriteLog "[ERROR] $description failed."
	}

	return $proc.ExitCode
}

# *****************************************************************
# 実行処理部
# *****************************************************************
WriteLog ("[BEGIN] " + $MyInvocation.MyCommand.Name)

$dClass = [System.Management.Automation.Host.ChoiceDescription]
$cClass = "System.Collections.ObjectModel.Collection"

$descriptions = New-Object "$cClass``1[$dClass]"
 
 # 選択肢処理
$questions | %{$descriptions.Add((New-Object $dclass $_))} 
$caption = "Target Selection"  
$message = "Which branch?"  
$result =  $host.UI.PromptForChoice($caption, $message, $descriptions,0) 
$selection = $descriptions[$result].Label.replace("&","")
if ($selection.Remove($selection.IndexOf(":")) -eq 1) {
  WriteLog "Exit Process."
  exit
}

# 選択されたブランチの取得
$branchName = $selection.Remove(0,$selection.IndexOf(":")+1)

if(![System.IO.Directory]::Exists($projectDir)){
	WriteLog "[ERROR] Project directory did not exist. ""$projectDir"""
	exit
}

# カレントディレクトリ移動
Set-Location $projectDir
if((Get-Location).Provider.Name -eq "FileSystem"){
	[System.IO.Directory]::SetCurrentDirectory($projectDir)
	WriteLog "[INFO] Current directory > ""$projectDir"""
}

# ***************************
# ブランチのチェックアウト
# ***************************
$exitCode = ExecuteProcess "git" "checkout $branchName" "Git checkout"
if($exitCode -ne 0){
	exit
}

# ***************************
# ブランチのPULL
# ***************************
$exitCode = ExecuteProcess "git" "pull origin $branchName" "Git pull"
if($exitCode -ne 0){
	exit
}

# ***************************
# ビルド
# ***************************
$exitCode = ExecuteProcess "msbuild" "/t:Build" "Build"
if($exitCode -ne 0){
	exit
}

## ***************************
## デプロイ
## ***************************
#$exitCode = ExecuteProcess "msbuild" "/t:Deploy" "Database update"
#if($exitCode -ne 0){
#	exit
#}

WriteLog ("[END] " + $MyInvocation.MyCommand.Name)
exit
