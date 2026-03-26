# Define variables
$tenantId = "XXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Replace with your tenant ID
$clientId = "XXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Replace with your application (client) ID
$clientSecret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Replace with your client secret
$resource = "https://graph.microsoft.com"
$authority = "https://login.microsoftonline.com/$tenantId"
 
# Get the OAuth token
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}
 
$tokenResponse = Invoke-RestMethod -Method Post -Uri "$authority/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $tokenResponse.access_token
 
# Define the date range for the audit log search
$startDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")  # Start date (7 days ago)
$endDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")  # End date (today)
 
# Define the output file path
$outputFile = "C:\AuditLogs\AuditLogRecords-XXX.csv"
 
# Search the unified audit log
$uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?&$filter=createdDateTime ge $startDate and createdDateTime le $endDate"
$headers = @{
    Authorization = "Bearer $token"
}
 
$auditLogs = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
 
# Export the audit logs to a CSV file
$auditLogs.value | Export-Csv -Path $outputFile -NoTypeInformation
 
Write-Host "Audit logs have been downloaded and saved to $outputFile"

#Email portion of the script 
$TenantId_B = "XXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Replace with your tenant ID
$ClientId_B = "XXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Replace with your application (client) ID
$ClientSecret_B = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Replace with your client secret
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret_B -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId_B, $ClientSecretPass

#Connect to Microsoft Graph with Client Secret
Connect-MgGraph -TenantId $TenantId_B -ClientSecretCredential $ClientSecretCredential -NoWelcome

$recipientAddress = "XXX@XXXX.com"  # Replace with the recipient's email address
$emailSubject = "SOC Audit Log File - $(Get-Date -Format 'yyyy-MM-dd')"
$emailBody = "Hi,`nPlease find the attached SOC log file."
$type = "Text"

#attachment
$filePath = "C:\AuditLogs\AuditLogRecords-XXX.csv"
$fileName = [System.IO.Path]::GetFileName($filePath)
Add-Type -AssemblyName System.Web
$contentType =[System.Web.MimeMapping]::GetMimeMapping($fileName) 

$params = @{
  Message = @{
    Subject = $emailSubject
    Body = @{
      ContentType = $type
      Content = $emailBody
    }
    ToRecipients = @(
      @{
         EmailAddress = @{
          Address = $recipientAddress
        }
       }
     )
    CcRecipients = @(
      @{
         EmailAddress = @{
          Address = "XXX"
        }
      },
      @{
         EmailAddress = @{
          Address = "XXX"
        }
      },
      @{
         EmailAddress = @{
          Address = "XXX"
        }
      }
    )
     attachments = @(
      @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        Name = $fileName
        ContentType = $contentType
        ContentBytes = [Convert]::ToBase64String([IO.File]::ReadAllBytes($filePath))
      }
     )
  }
}

Send-MgUserMail -UserId "SenderEmailAddress" -BodyParameter $params