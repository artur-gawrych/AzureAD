function Get-M365ConditionalAccessPolicy {
    [CmdletBinding()]
    param(
        # Name of the Conditional Access Policy
        [Parameter(Mandatory = $false)]
        $ConditionalAccessPolicyName
    )
    #Checking if any Conditional Access Policy exists
    $CAPs = Get-AzureADMSConditionalAccessPolicy
    if (!$CAPs) {
        Write-Host 'No Conditional Access Policies Exists on the tenant'
        break
    }
    if ($ConditionalAccessPolicyName) {
        $CAPNameCheck = Get-AzureADMSConditionalAccessPolicy | Where-Object { $_.DisplayName -eq $ConditionalAccessPolicyName }
        if ($CAPNameCheck) {
            foreach ($CAP in $CAPNameCheck) {
                $CAPs = [PSCustomObject]@{
                    'Name'                      = $CAP.DisplayName
                    'State'                     = if ($CAP.State -eq 'enabled') {
                        'ON'
                    } elseif ($CAP.State -eq 'disabled') {
                        'OFF'
                    } elseif ($CAP.State -eq 'enabledForReportingButNotEnforced') {
                        'REPORT ONLY'
                    }else{
                        'UNABLE TO DEFINE'
                    }
                    'Access Control'            = if ($CAP.GrantControls.BuiltInControls -contains 'Block') {
                        'BLOCK'
                    } else {
                        'ALLOW'
                    }
                    'Access Control Methods'    = $CAP.GrantControls.BuiltInControls
                    'Required Contols'          = if ($CAP.GrantControls._Operator -eq 'OR') {
                        'Require one of selected controls'
                    } else {
                        'Requre all controls'
                    }
                }
                $CAPs
            }
        } else {
            Write-Host "Contitional Access Policy named '$ConditionalAccessPolicyName' does not exist!" -ForegroundColor Red
        }
    } else {
        foreach ($CAP in $CAPs) {
            $CAPs = [PSCustomObject]@{
                'Name'                      = $CAP.DisplayName
                'State'                     = if ($CAP.State -eq 'enabled') {
                    'ON'
                } elseif ($CAP.State -eq 'disabled') {
                    'OFF'
                } elseif ($CAP.State -eq 'enabledForReportingButNotEnforced') {
                    'REPORT ONLY'
                }else{
                    'UNABLE TO DEFINE'
                }
                'Access Control'            = if ($CAP.GrantControls.BuiltInControls -contains 'Block') {
                    'BLOCK'
                } else {
                    'ALLOW'
                }
                'Access Control Methods'    = $CAP.GrantControls.BuiltInControls
                'Required Contols'          = if ($CAP.GrantControls._Operator -eq 'OR') {
                    'Require one of selected controls'
                } else {
                    'Requre all controls'
                }
            }
            $CAPs
        }
        
    }
}
function New-M365ConditionalAccessPolicy {
    [CmdletBinding()]
    param (
        # Name of the Azure AD security group
        [Parameter(Mandatory = $false)]
        $SecurityGroupName = 'MFA Required',
        # Name of the Conditional Access Policy
        [Parameter(Mandatory = $false)]
        $ConditionalAccessPolicyName = 'GRANT - Require MFA'
    )
    # Check for AzureAD module
    $AZAD = Get-Module -Name AzureAD -ListAvailable
    $AZADP = Get-Module -Name AzureADPreview -ListAvailable
    if (!$AZAD -and !$AZADP) {
        Write-Host "Please install AzureAD Module ('Install-Module AzureAD') to continue."
        break;
    }
    # Check if the Conditional Access Policy alredy exist
    $CAPNameCheck = Get-AzureADMSConditionalAccessPolicy | Where-Object { $_.DisplayName -eq $ConditionalAccessPolicyName }
    if ($CAPNameCheck) {
        Write-Host "Policy named $ConditionalAccessPolicyName already exist on the tenant. Exiting..." -ForegroundColor Red
        break;
    }
    # Check if the Azure AD Scurity group alredy exist, if not create it.
    $SGNameCheck = Get-AzureADGroup | Where-Object { $_.DisplayName -eq $SecurityGroupName }
    if ($SGNameCheck) {
        Write-Host "Azure AD group named $SecurityGroupName already exist." -ForegroundColor Green
    } else {
        Write-Host "Creating new Azure AD securit group - $SecurityGroupName" -ForegroundColor Green
        New-AzureADGroup -DisplayName $SecurityGroupName -MailEnabled $false -MailNickName 'NotSet' -SecurityEnabled $true
    }
    # Getting the Security gorup ID
    $SG = Get-AzureADGroup | Where-Object { $_.DisplayName -eq $SecurityGroupName }
    $SGID = $SG.ObjectId
    # Setting the conditions
    $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
    $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
    $conditions.Applications.IncludeApplications = 'All'
    $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
    $conditions.Users.IncludeGroups = $SGID
    $conditions.ClientAppTypes = @('browser', 'mobileAppsAndDesktopClients', 'exchangeActiveSync', 'other')
    $conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
    $conditions.Locations.IncludeLocations = 'All'
    $conditions.Locations.ExcludeLocations = 'AllTrusted'
    $conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
    $conditions.Platforms.IncludePlatforms = 'All'
    #Setting the controls
    $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
    $controls._Operator = 'OR'
    $controls.BuiltInControls = 'mfa'
    #Setting the parameters
    $params = @{
        DisplayName   = $ConditionalAccessPolicyName 
        State         = 'enabledForReportingButNotEnforced' 
        Conditions    = $conditions 
        GrantControls = $controls
    }
    New-AzureADMSConditionalAccessPolicy @params
}
