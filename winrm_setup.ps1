$winrm_cmd = {
	winrm quickconfig -q 
	winrm set winrm/config '@{MaxTimeoutms="1800000"}'
	winrm set winrm/config/service '@{AllowUnencrypted="true"}'
	winrm set winrm/config/service/auth '@{Basic="true"}'
}

# Configure WinRM on Azure Windows instance
& $winrm_cmd

$hostname = $(Invoke-RestMethod -Headers @{"Metadata"="true"} -URI "http://169.254.169.254/metadata/instance/compute/name?api-version=2019-02-01&&format=text")

# Generate self signed certificate for WinRM usage
New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation Cert:\LocalMachine\My
New-Item WSMan:\localhost\Listener -Address * -Transport HTTPS -HostName $hostname -CertificateThumbPrint $(ls Cert:\LocalMachine\My).Thumbprint -Force
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Set-MpPreference -DisableRealtimeMonitoring $true
