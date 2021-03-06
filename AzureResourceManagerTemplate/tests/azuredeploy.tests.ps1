#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent $here
$template = Split-Path -Leaf $here

Describe "Template: $template" -Tags Unit {
    
    Context "Template Syntax" {
        
        It "Has a JSON template" {        
            "$here\azuredeploy.json" | Should Exist
        }
        
        It "Has a parameters file" {        
            "$here\azuredeploy.parameters.json" | Should Exist
        }
        
        It "Has a metadata file" {        
            "$here\metadata.json" | Should Exist
        }

        It "Converts from JSON and has the expected properties" {
             $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'variables',
                                  'resources',                                
                                  'outputs' | Sort-Object
            $templateProperties = (get-content "$here\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | Sort-Object -Property NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }

        
        It "Passes template#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent $here
$template = Split-Path -Leaf $here

# Generate a GUID to be prepended to a resource group name which will be specifically created to perform template validation with a specified parameter file.
# After we validate the template + parameter file validation we delete the resource group.
# Note this does slow down the tests.
$ShortGUID = ([system.guid]::newguid().guid).Substring(0,5)
$TempValidationRG = "$ShortGUID-Pester-Validation-RG"
$Location = 'northeurope'

$ParameterFileTestCases = @()
ForEach( $File in (dir "$here\azuredeploy.parameters*.json" | select -ExpandProperty Name) )
{
    $ParameterFileTestCases += @{ ParameterFile = $File }
}

Describe "Template: $template" -Tags Unit {
    BeforeAll {
        New-AzureRmResourceGroup -Name $TempValidationRG -Location $Location
    }

    AfterAll {
        Remove-AzureRmResourceGroup $TempValidationRG -Force
    }

    # Check that the template contains the elements that we expect.
    Context "Template Syntax" {
        
        It "Has a JSON template" {        
            "$here\azuredeploy.json" | Should Exist
        }
        
        It "Has a parameters file" {        
            "$here\azuredeploy.parameters*.json" | Should Exist
        }
        
        It "Has a metadata file" {        
            "$here\metadata.json" | Should Exist
        }

        It "Converts from JSON and has the expected properties" {
             $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'variables',
                                  'resources',                                
                                  'outputs' | Sort-Object
            $templateProperties = (get-content "$here\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | Sort-Object -Property NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }

    # Check that each parameter file has the expected properties
    Context "Parameter File Syntax" {
        It "Parameter file <ParameterFile> contains the expected properties" -TestCases $ParameterFileTestCases {
            Param( $ParameterFile )
            $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters' | Sort-Object
            $templateFileProperties = (get-content "$here\$ParameterFile" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | Sort-Object -Property NoteProperty | % Name
            $templateFileProperties | Should Be $expectedProperties
        }
    }

    # Use Test-AzureRmResourceGroupDeployment to validate the template against each parameter file.
    # Note the deployment of the template can still fail - this simply checks that the schema for each of the resources is correct and that the parameter file is correct.
    # Deployments can still fail for other reasons and the parameter file may still be wrong e.g. we specify a subnet address prefix in the parameter file that does not fall within the VNET address spaces
    Context "Template Validation" {
        
        It "Template $here\azuredeploy.json and parameter file <ParameterFile> passes validation" -TestCases $ParameterFileTestCases {
            Param( $ParameterFile )
            # Complete mode - will deploy everything in the template from scratch. If the resource group already contains things (or even items that are not in the template) they will be deleted first.
            # If it passes validation no output is returned, hence we test for NullOrEmpty
            $ValidationResult = Test-AzureRmResourceGroupDeployment -ResourceGroupName $TempValidationRG -Mode Complete -TemplateFile "$here\azuredeploy.json" -TemplateParameterFile "$here\$ParameterFile"
            $ValidationResult | Should BeNullOrEmpty
        }
    }
}
 validation" {            
            $ShortGUID = ([system.guid]::newguid().guid).Substring(0,5)
            $TempValidationRG = "$ShortGUID-Pester-Validation-RG"
            $Location = 'northeurope'
            New-AzureRmResourceGroup -Name $TempValidationRG -Location $Location
            $ValidationResult = Test-AzureRmResourceGroupDeployment -ResourceGroupName $TempValidationRG -Mode Complete -TemplateFile "$here\azuredeploy.json" -TemplateParameterFile "$here\azuredeploy.parameters.json"
            Remove-AzureRmResourceGroup $TempValidationRG -Force
            $ValidationResult | Should BeNullOrEmpty                        
        }

    }
}
