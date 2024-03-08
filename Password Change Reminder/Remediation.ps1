# Gets the current logged on user
$loggedonuser = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]

# Gets the USID of the current logged on user
$currentusersid = Get-WmiObject -Class win32_computersystem | Select-Object -ExpandProperty Username | ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }


$ExpDate = Get-ItemPropertyValue -Path "REGISTRY::HKEY_USERS\$currentusersid\SOFTWARE\PasswordReminder\" -Name PasswordExpiration

##USE THIS CODE HERE TO CREATE A BASE 64 STRING BUT DONT INCLUDE IN SCRIPT
<# [string]$sStringToEncode= "Dein Password läuft bald ab!" $Base64Encode=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sStringToEncode)) $Base64Encode #>

<# Convert Variable to Encode

$TitleText = "Dein Password läuft bald ab!" 
$BodyText1 ="Dein Windows Passwort läuft bald ab! Spare Dir die Schwierigkeiten und ändere dein Passwort noch heute."
$BodyText2 = "Um dein Passwort zu ändern, drücke CTRL+ALT+DEL (STRG+ALT+ENTF) und wähle 'Kennwort ändern', anschließend starte dann deinen PC neu. Ansonsten besteht die Möglichkeit dass du dich ausperrst."
$ExpText = "Dein Password läuft am ab: "

[string]$sStringToEncode= "Dein Password läuft bald ab!" 
$Base64Encode=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sStringToEncode))
$Base64Encode
#>

## Encoding $TitleText ##
$Base64EncodeString = "RGVpbiBQYXNzd29yZCBsw6R1ZnQgYmFsZCBhYiE="
$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
$TitleText = $Base64Text

## Encoding $BodyText1 ##
$Base64EncodeString = "RGVpbiBXaW5kb3dzIFBhc3N3b3J0IGzDpHVmdCBiYWxkIGFiISBTcGFyZSBEaXIgZGllIFNjaHdpZXJpZ2tlaXRlbiB1bmQgw6RuZGVyZSBkZWluIFBhc3N3b3J0IG5vY2ggaGV1dGUu"
$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
$BodyText1 = $Base64Text

## Encodign $BodyText2 ##
$Base64EncodeString = "VW0gZGVpbiBQYXNzd29ydCB6dSDDpG5kZXJuLCBkcsO8Y2tlIENUUkwrQUxUK0RFTCAoU1RSRytBTFQrRU5URikgdW5kIHfDpGhsZSAnS2VubndvcnQgw6RuZGVybicsIGFuc2NobGllw59lbmQgc3RhcnRlIGRhbm4gZGVpbmVuIFBDIG5ldS4gQW5zb25zdGVuIGJlc3RlaHQgZGllIE3DtmdsaWNoa2VpdCBkYXNzIGR1IGRpY2ggYXVzcGVycnN0Lg=="
$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
$BodyText2 = $Base64Text


## Encodign $ExpText ##
$Base64EncodeString = "RGVpbiBQYXNzd29yZCBsw6R1ZnQgYW0gYWI6"
$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
$ExpText = $Base64Text +" " + $ExpDate

#Remove this if you want to use an URL and your own image instead
#$HeroImagePath = "\\demuc-file\Clients\Workplace\ToastHeroImageSecurity.jpg"


#If you want to you use your own URL use theese variables instead, also uncomment line 100 & 101
#$HeroImageFile = "Paste URL here if you want to download your own image from e.g an Azure Storage Account"
#$HeroImageName = "img1.jpg"

$Action = "https://account.activedirectory.windowsazure.com/ChangePassword.aspx"
$Infovideo = "" ## Add your URL to Information about password change for your Users

$WindirTemp = Join-Path $Env:Windir -Childpath "Temp"
$UserTemp = $Env:Temp
$UserContext = [Security.Principal.WindowsIdentity]::GetCurrent()

Switch ($UserContext) {
    { $PSItem.Name -Match       "System"    } { Write-Output "Running as System"  ; $Temp =  $UserTemp   }
    { $PSItem.Name -NotMatch    "System"    } { Write-Output "Not running System" ; $Temp =  $WindirTemp }
    Default { Write-Output "Could not translate Usercontext" }
}

$logfilename = "PasswordNotificationRE"
$logfile = Join-Path $Temp -Childpath "$logfilename.log"

$LogfileSizeMax = 100

##############################
## Functions
##############################

function Test-WindowsPushNotificationsEnabled() {
	$ToastEnabledKey = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name ToastEnabled -ErrorAction Ignore).ToastEnabled
	if ($ToastEnabledKey -eq "1") {
		Write-Output "Toast notifications are enabled in Windows"
		return $true
	}
	elseif ($ToastEnabledKey -eq "0") {
		Write-Output "Toast notifications are not enabled in Windows. The script will run, but toasts might not be displayed"
		return $false
	}
	else {
		Write-Output "The registry key for determining if toast notifications are enabled does not exist. The script will run, but toasts might not be displayed"
		return $false
	}
}

function Display-ToastNotification() {

	$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
	$Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

	# Load the notification into the required format
	$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
	$ToastXml.LoadXml($Toast.OuterXml)
		
	# Display the toast notification
	try {
		Write-Output "All good. Displaying the toast notification"
		[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
	}
	catch { 
		Write-Output "Something went wrong when displaying the toast notification"
		Write-Output "Make sure the script is running as the logged on user"    
	}
	if ($CustomAudio -eq "True") {
		Invoke-Command -ScriptBlock {
			Add-Type -AssemblyName System.Speech
			$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
			$speak.Speak($CustomAudioTextToSpeech)
			$speak.Dispose()
		}    
	}
}

function Test-NTSystem() {  
	$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
	if ($currentUser.IsSystem -eq $true) {
		$true  
	}
	elseif ($currentUser.IsSystem -eq $false) {
		$false
	}
}

##############################s
## Scriptstart
##############################

If ($logfilename) {
    If (((Get-Item -ErrorAction SilentlyContinue $logfile).length / 1MB) -gt $LogfileSizeMax) { Remove-Item $logfile -Force }
    Start-Transcript $logfile -Append | Out-Null
    Get-Date
}

	#$HeroImagePath = Join-Path -Path $Env:Temp -ChildPath $HeroImageName
	#If (!(Test-Path $HeroImagePath)) { Start-BitsTransfer -Source $HeroImageFile -Destination $HeroImagePath }	

	##Setting image variables
	$LogoImage = ""
	$HeroImage = $HeroImagePath
	$RunningOS = Get-CimInstance -Class Win32_OperatingSystem | Select-Object BuildNumber

	<# $isSystem = Test-NTSystem
	if ($isSystem -eq $True) {
		Write-Output "Aborting script"
		Exit 1
	}#>

	$WindowsPushNotificationsEnabled = Test-WindowsPushNotificationsEnabled

	$PSAppStatus = "True"

	if ($PSAppStatus -eq "True") {
		$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
		$App = "Microsoft.CompanyPortal_8wekyb3d8bbwe!App"
		
		if (-NOT(Test-Path -Path "$RegPath\$App")) {
			New-Item -Path "$RegPath\$App" -Force
			New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD"
		}
		
		if ((Get-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -ErrorAction SilentlyContinue).ShowInActionCenter -ne "1") {
			New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD" -Force
		}
	}

	$AttributionText = "Information"
	
	## Button 1 Encoding ##
	$Base64EncodeString = "UGFzc3dvcmQgw6RuZGVybg=="
	$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
	$ActionButtonContent = $Base64Text



	## Button 2 Encoding ##
	$Base64EncodeString = "U3DDpHRlciBlcmlubmVybg=="
	$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
	$DismissButtonContent = $Base64Text

	## Button 3 Encoding ##
	$Base64EncodeString = "SW5mb3ZpZGVv"
	$Base64Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64EncodeString))
	$InfovideoContent = $Base64Text
	

	$CustomAudio = "False"
	$CustomAudioTextToSpeech = $Xml.Configuration.Option | Where-Object {$_.Name -like 'CustomAudio'} | Select-Object -ExpandProperty 'TextToSpeech'

	
	$Scenario = "Reminder"

	
	# Formatting the toast notification XML
	# Create the default toast notification XML with action button and dismiss button
	[xml]$Toast = @"
	<toast scenario="$Scenario">
	<visual>
	<binding template="ToastGeneric">
		<image placement="hero" src="$HeroImage"/>
		<image id="1" placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>
		<text placement="attribution">$AttributionText</text>
		<text>$HeaderText</text>
		<group>
			<subgroup>
				<text hint-style="title" hint-wrap="true" >$TitleText</text>
			</subgroup>
		</group>
		<group>
			<subgroup>     
				<text hint-style="body" hint-wrap="true" >$BodyText1<utf-8/></text>
			</subgroup>
		</group>
		<group>
			<subgroup>     
				<text hint-style="body" hint-wrap="true" >$BodyText2<utf-8/></text>
				<text hint-style="body" hint-wrap="true" >$ExpText<utf-8/></text>
			</subgroup>
		</group>
	</binding>
	</visual>
	<actions>
		<action activationType="protocol" arguments="$Action" content="$ActionButtonContent"/>
		<action activationType="system" arguments="dismiss" content="$DismissButtonContent"/>
		<action activationType="protocol" arguments="$InfoVideo" content="$InfovideoContent"/>
	</actions>
	</toast>
"@
	
	Display-ToastNotification

If ($logfilename) {
    Stop-Transcript | Out-Null
}

Exit 0