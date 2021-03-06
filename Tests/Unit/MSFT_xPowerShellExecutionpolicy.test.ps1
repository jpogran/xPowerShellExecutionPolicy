<#
.Synopsis
   Unit test for PowerShellExecutionPolicy DSC Resource
#>

$Global:DSCModuleName      = 'xPowerShellExecutionPolicy'
$Global:DSCResourceName    = 'MSFT_xPowerShellExecutionPolicy'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

$Global:invalidPolicyThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does "
$Global:invalidPolicyThrowMessage += "not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" "
$Global:invalidPolicyThrowMessage += "specified by the ValidateSet attribute. Supply an argument that is in the set and then "
$Global:invalidPolicyThrowMessage += "try the command again."

$Global:invalidPolicyScopeThrowMessage = "Cannot validate argument on parameter 'Scope'. The argument `"badParam`" does "
$Global:invalidPolicyScopeThrowMessage += "not belong to the set `"CurrentUser,LocalMachine,MachinePolicy,Process,UserPolicy`" "
$Global:invalidPolicyScopeThrowMessage += "specified by the ValidateSet attribute. Supply an argument that is in the set and then "
$Global:invalidPolicyScopeThrowMessage += "try the command again."

# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Get-TargetResource -ExecutionPolicy 'badParam' } | should throw $invalidPolicyThrowMessage
            }

            It 'Returns correct execution policy' {
                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy)

                $result.ExecutionPolicy | should be $(Get-ExecutionPolicy)
            }

            It 'Throws when passed an invalid execution policy Scope' {
                { Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -Scope "badParam" } | should throw $invalidPolicyScopeThrowMessage
            }

            It 'Returns correct execution policy for the correct Scope' {
                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy -Scope 'LocalMachine') -Scope 'LocalMachine'
                $result.ExecutionPolicy | should be $(Get-ExecutionPolicy -Scope 'LocalMachine')
                $result.Scope | should be 'LocalMachine'
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Test-TargetResource -ExecutionPolicy 'badParam' } | should throw $invalidPolicyThrowMessage
            }

            It 'Returns true when current policy matches desired policy' {
                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) | should be $True
            }

            It 'Returns false when current policy does not match desired policy' {
                Mock -CommandName Get-ExecutionPolicy -MockWith { "Restricted" }

                Test-TargetResource -ExecutionPolicy "Bypass" | should be $false
            }

            It 'Throws when passed an invalid execution policy Scope' {
                { Test-TargetResource -ExecutionPolicy 'badParam' } | should throw $invalidPolicyScopeThrowMessage
            }

            It 'Returns true when current policy matches desired policy with correct Scope' {
                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) | should be $True
            }

            It 'Returns false when current policy does not match desired policy with correct Scope' {
                Mock -CommandName Get-ExecutionPolicy -MockWith { "Restricted" }

                Test-TargetResource -ExecutionPolicy "Bypass" -Scope 'LocalMachine'| should be $false
            }

        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Set-TargetResource -ExecutionPolicy 'badParam' } | should throw $invalidPolicyThrowMessage
            }

            It 'Throws when passed an invalid execution policy' {
                { Set-TargetResource -ExecutionPolicy 'LocalMachine' -Scope "badParam" } | should throw $invalidPolicyScopeThrowMessage
            }

            It 'Set-ExecutionPolicy scope warning exception is caught' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { Throw 'Windows PowerShell updated your execution policy successfully.' }

                $result = Set-TargetResource -ExecutionPolicy "Bypass"

                $result | should be $null
            }

            It 'Throws non-caught exceptions'{
                Mock -CommandName Set-ExecutionPolicy -MockWith { Throw 'Throw me!' }

                { Set-TargetResource -ExecutionPolicy "Bypass" } | should throw 'Throw me!'
            }

            It 'Sets execution policy' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { }

                Set-TargetResource -ExecutionPolicy "Bypass"

                Assert-MockCalled -CommandName Set-ExecutionPolicy -Exactly 1 -Scope It
            }

            It 'Sets execution policy in spesified Scope' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { }

                Set-TargetResource -ExecutionPolicy "Bypass" -Scope 'LocalMachine'

                Assert-MockCalled -CommandName Set-ExecutionPolicy -Exactly 1 -Scope It
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

