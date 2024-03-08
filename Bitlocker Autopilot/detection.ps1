$TPM = (Get-BitlockerVolume).KeyProtector.KeyProtectorType
if ($TPM -contains "TpmPin" ) {
        write-host "Found it!"
}

