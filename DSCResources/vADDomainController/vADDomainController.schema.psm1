
configuration vADDomainController {
    param (
        [Parameter()] [ValidateNotNull()]
        [System.String] $DomainName = 'lab.local',
        
        [Parameter()] [ValidateNotNull()]
        [PSCredential] $Credential = (Get-Credential -Username 'Administrator' -Message "Enter '$DomainName\Administrator' password."),

        [Parameter()]
        [System.Boolean] $IncludeManagementTools = $true
    )
 
    # Import the module that defines custom resources
    Import-DscResource -Module xActiveDirectory;

    foreach ($feature in @('DNS','AD-Domain-Services','RSAT-AD-PowerShell')) {
        WindowsFeature $($feature.Replace('-','')) {
            Ensure = 'Present';
            Name = $feature;
        }
    }

    if ($IncludeManagementTools) {
        foreach ($feature in @('RSAT-AD-AdminCenter','RSAT-ADDS','RSAT-AD-Tools','RSAT-Role-Tools','RSAT-DNS-Server')) {
            WindowsFeature $($feature.Replace('-','')) {
                Ensure = 'Present';
                Name = $feature;
            }
        }
    }

    xWaitForADDomain 'WaitForADDomain' {
        DomainName = $DomainName;
        DomainUserCredential = $Credential;
        RetryIntervalSec = 30;
        RetryCount = 20;
        DependsOn = '[WindowsFeature]ADDomainServices';
    }

    xADDomainController 'ADDomainController' {
        DomainName = $DomainName;
        SafemodeAdministratorPassword = $Credential;
        DomainAdministratorCredential = $Credential;
        DependsOn = '[xWaitForADDomain]WaitForADDomain';
    }
}
