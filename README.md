# M365 MFA Setup

1. Connect to AzureAD
2. Run `. .\M365MFA.ps1` in PowerShell to add the function to the session scope.
3. Run `New-M365ConditionalAccessPolicy`, by default it will use **"MFA Required"** as a security group name and **"GRANT - Require MFA"** as a conditional policy name, you can change those by using the `-SecurityGroupName` or `-ConditionalAccessPolicyName` property respectively.