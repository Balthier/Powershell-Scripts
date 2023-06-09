###############
## Includes ###
###############
. ".\Common-Functions.ps1"
. ".\JSON 1.7.ps1"

#####################################################
# Purpose: Helper functions to support API scripting examples.
# 
# Copyright (c) 2014 TeamViewer GmbH
# Example created 2014-02-20
# Version 1.1
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#####################################################

##################
# script variables
##################

# version of the TeamViewer API
$apiVersion = "v1"

# url of the TeamViewer Management Console API
$tvApiBaseUrl = "https://webapi.teamviewer.com"

###############
# API Functions
###############


#Creates a single company user:
#   Field values in $dictUser will be used to create the given user.
#   Defaults for some missing fields (permissions, password, language) must be provided.
Function CreateUser($AccessToken, $dictUser, $strDefaultUserPermissions, $strDefaultUserLanguage, $strDefaultUserPassword ) {
	Write-Host ("")
	Write-Host ("Creating user [" + $dictUser.email + "]...")
	Write-Host ("Request [POST] /api/$apiVersion/users")
    $result = $false
    try {        
		$req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users")
		$req.Method = "POST"
		$req.Headers.Add("Authorization: Bearer $AccessToken")
		$req.ContentType = "application/json; charset=utf-8"
		
		#define fields		
		$createPayload = @{}
		
		#name parameter
		if($dictUser.PSObject.Properties.Match('name') -and $dictUser.name.length -gt 0) {
			$createPayload.name = $dictUser.name			
		}
		else {
			Write-Host ("Field [name] is missing. Can't create user.")
			return $false
		}
		
		#email parameter
		if($dictUser.PSObject.Properties.Match('email') -and $dictUser.email.length -gt 5) {
			$createPayload.email = $dictUser.email			
		}
		else {
			Write-Host ("Field [email] is missing. Can't create user.")
			return $false
		}		
		
		#password parameter
		if($dictUser.PSObject.Properties.Match('password') -and $dictUser.password.length -gt 5) {
			$createPayload.password = $dictUser.password
		}
		else {
			$createPayload.password = $strDefaultUserPassword
		}
		
		#permission parameter
		if ($dictUser.PSObject.Properties.Match('permissions') -and $dictUser.permissions.length -gt 0) {
			$createPayload.permissions = $dictUser.permissions			
		}
		else {
			$createPayload.permissions = $strDefaultUserPermissions
		}
		
		#language parameter
		if ($dictUser.PSObject.Properties.Match('language') -and $dictUser.language.length -gt 0) {
			$createPayload.language = $dictUser.language			
		}
		else {
			$createPayload.language = $strDefaultUserLanguage
		}
		
		$psobject = new-object psobject -Property $createPayload		
		$jsonPayload = $psobject | ConvertTo-Json -NoTypeInformation -Depth 1		
		
		#<--workaround for bug in ConvertTo-Json function in combination with hashtables (should not be required when porting to PowerShell 3.0)
		#cut out the nested object 
		$innerObjStart = $jsonPayload.LastIndexOf('{')
		$innerObjEnd = $jsonPayload.IndexOf('}') + 1		
		$jsonPayload = $jsonPayload.Substring($innerObjStart, $innerObjEnd - $innerObjStart)
		#-->
		
		Write-Host "Payload: $jsonPayload"
		
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)		
		$requestStream = $req.GetRequestStream()
		$requestStream.Write($payloadBytes, 0, $payloadBytes.length)
		$requestStream.Close()
		
		$res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode		
		Write-Host "$statusCode $statusStr"
		
		if ($statusCode -eq 200) {
			Write-Host "User created."
			$result = $true
		}
		else {
			Write-Host "Error creating user."
			$result = $false
		}
	}
    catch [Net.WebException] {        
		Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
		$sr = new-object System.IO.StreamReader $resstream
		$value = $sr.ReadToEnd()
		Write-Host $value
		
		$result = $false
	} 
    finally {
		if ($res) {
			$res.Close()
			Remove-Variable res
		}
	}
	return $result
}

#Deactivates a single company user:
Function DeactivateUser($AccessToken, $userId, $user) {
	# Write-Host ("")
	# Write-Host ("Deactivating user " + $user + "...")
	# Write-Host ("Request [PUT] /api/$apiVersion/users/" + $userId )
    $result = $false
	
    try {        
		$req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users/" + $userId)
		$req.Method = "PUT"
		$req.Headers.Add("Authorization: Bearer $accessToken")		
		$req.ContentType = "application/json; charset=utf-8"        
		
		#define update fields		
		$updatePayload = @{}
		
		#active flag
		$jsonPayload = "{""active"": false}"
		
		# Write-Host "Payload: $jsonPayload"
		
		$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)		
		$requestStream = $req.GetRequestStream()
		$requestStream.Write($payloadBytes, 0,$payloadBytes.length)
		$requestStream.Close()
		
		$res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		# Write-Host "$statusCode $statusStr"
		
		if ($statusCode -eq 204) {
			# Write-Host "User deactivated."
			$result = $true
		}
		else {
			Write-Host "Error deactivating user."
			$result = $false
		}
	}
    catch [Net.WebException] {        
		Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
		$sr = new-object System.IO.StreamReader $resstream
		$value = $sr.ReadToEnd()
		Write-Host $value
		
		$result = $false
	} 
    finally {
		if ($res) {
			$res.Close()
			Remove-Variable res
		}
	}
}

# Check if API is available and verify token is valid
function PingAPI($accessToken) {
	# Write-Host ("")
	# Write-Host ("Ping API...")
	# Write-Host ("Request [GET] /api/$apiVersion/ping")
    $result = $false	
	
    try {
        
        $req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/ping")
        $req.Method = "GET"
        $req.Headers.Add("Authorization: Bearer $accessToken")		
		
        $res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		# Write-Host "$statusCode $statusStr"
		
        $resstream = $res.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $result = $sr.ReadToEnd()
		
		if($statusCode -ne 200 ) {
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
        $jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
        $tokenValue =  $jsonResponse.token_valid
		
		if($tokenValue -eq $true) {
			# Write-Host ("Ping: Token is valid")
			$result = $true
		}
		else {		
			Write-Host ("Ping: Token is invalid")
			$result = $false
		}		
	}
    catch {
        Write-Host ("Ping: Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
        $sr = new-object System.IO.StreamReader $resstream
        $value = $sr.ReadToEnd()
		Write-Host $value
		
        $result = "false"
	} 
    finally {
        if ($res) {
            $res.Close()
            Remove-Variable res
		}
	}
	return $result
}

# get all users of a company with all available fields
function GetAllUsersAPI($accessToken,$email) {
    # Write-Host ("")
    # Write-Host ("Get all users...")
	# Write-Host ("Request [GET] /api/$apiVersion/users?email=" + $email)
    $result = $false
	$email = 
    try {        
		$req = [System.Net.WebRequest]::Create($tvApiBaseUrl + "/api/" + $apiVersion + "/users?email=" + $email)
		$req.Method = "GET"
		$req.Headers.Add("Authorization: Bearer $accessToken")
		
		$res = $req.GetResponse()
		$statusStr = $res.StatusCode
		$statusCode = [int]$res.StatusCode
		
		# Write-Host "$statusCode $statusStr"
		
		if ($statusCode -ne 200 ) {
			Write-Host "Unexpected response code. Received content was:"
			Write-Host $result
			$result = $false
			return $result
		}
		
		$resstream = $res.GetResponseStream()
		$sr = new-object System.IO.StreamReader $resstream
		$result = $sr.ReadToEnd()
		
		$jsonResponse = ConvertFrom-Json -InputObject $result -Type String    
		$result =  $jsonResponse.users 
		# Write-Host ("Request ok!")
	}
    catch [Net.WebException] {        
		Write-Host ("Request failed! The error was '{0}'." -f $_)
		
		Write-Host "Received content was:"		
		$resstream = $Error[0].Exception.InnerException.Response.GetResponseStream()
		$sr = new-object System.IO.StreamReader $resstream
		$value = $sr.ReadToEnd()
		Write-Host $value		
		
		$result = $false
	} 
    finally {
		if ($res) {
			$res.Close()
			Remove-Variable res
		}		
	}
	return $result
}

###############
## Functions ##
###############

Function checkTeamviewer($TVAPI) {
	PingAPI $TVAPI
}

Function searchTVUser($TVAPI,$email) {
	$APIStatus = checkTeamviewer $TVAPI
	if ($APIStatus) {
		$User = GetAllUsersAPI $TVAPI $email
		Return $User
	}
}

Function deactivateTVUser($TVAPI,$email,$UserID) {
	$APIStatus = checkTeamviewer $TVAPI
	if ($APIStatus) {
		DeactivateUser $TVAPI $UserID $email
	}
}
