<#
.SYNOPSIS

	Connects to a TFS Team Project Collection. 

.DESCRIPTION

	The Connect-TfsTeamProjectCollection cmdlet "connects" (initializes a Microsoft.TeamFoundation.Client.TfsTeamProjectCollection object) to a TFS Team Project Collection. That connection is subsequently kept in a global variable to be later reused until it's closed by a call to Disconnect-TfsTeamProjectCollection.

	Most cmdlets in the TfsCmdlets module require a TfsTeamProjectCollection object to be provided via their -Collection argument in order to access a TFS instance. Those cmdlets will use the connection opened by Connect-TfsTeamProjectCollection as their "default connection". In other words, TFS cmdlets (e.g. New-TfsWorkItem) that have a -Collection argument will use the connection provided by Connect-TfsTeamProjectCollection by default.

.PARAMETER Collection

	Specifies either a URL/name of the Team Project Collection to connect to, or a previously initialized TfsTeamProjectCollection object. 

	For more details, see the -Collection argument in the Get-TfsTeamProjectCollection cmdlet.

.PARAMETER Server

	Specifies either a URL or the name of the Team Foundation Server configuration server (the "root" of a TFS installation) to connect to, or a previously initialized Microsoft.TeamFoundation.Client.TfsConfigurationServer object.

	For more details, see the -Server argument in the Get-TfsConfigurationServer cmdlet.

.PARAMETER Credential

	Specifies a user account that has permission to perform this action. The default is the current user.

	Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet. If you type a user name, you will be prompted for a password.

	To connect to Visual Studio Online you must enable Alternate Credentials for your user profile and supply that credential in this argument.

	For more information on Alternate Credentials for your Visual Studio Online account, please refer to https://msdn.microsoft.com/library/dd286572#setup_basic_auth.

.PARAMETER Passthru

	Returns the results of the command. By default, this cmdlet does not generate any output.

.EXAMPLE

	Connect-TfsTeamProjectCollection -Collection http://tfs:8080/tfs/DefaultCollection

	Connects to a collection called "DefaultCollection" in a TF server called "tfs" using the default credentials of the logged-on user

.LINK
	
	Get-TfsTeamProjectCollection

.LINK

	https://msdn.microsoft.com/en-us/library/microsoft.teamfoundation.client.tfsteamprojectcollection.aspx

#>
Function Connect-TfsTeamProjectCollection
{
	[CmdletBinding()]
	[OutputType([Microsoft.TeamFoundation.Client.TfsTeamProjectCollection])]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[object] 
		$Collection,
	
		[Parameter(ValueFromPipeline=$true)]
		[object] 
		$Server,
	
		[Parameter()]
		[System.Management.Automation.Credential()]
		[System.Management.Automation.PSCredential]
		$Credential,

		[Parameter()]
		[switch]
		$Passthru
	)

	Process
	{
		$tpc = (Get-TfsTeamProjectCollection -Collection $Collection -Server $Server -Credential $Credential | Select -First 1)

		if (-not $tpc)
		{
			throw "Error connecting to TFS"
		}

		$tpc.EnsureAuthenticated()

		$Global:TfsTpcConnection = $tpc
		$Global:TfsTpcConnectionCredential = $Credential

		if ($Passthru)
		{
			return $tpc
		}
	}
}

<#
.SYNOPSIS

	Disconnects from the currently connected TFS Team Project Collection

.DESCRIPTION

	The Disconnect-TfsTeamProjectCollection removes the global variable set by Connect-TfsTeamProjectCollection. Therefore, cmdlets relying on a "default collection" as provided by Connect-TfsTeamProjectCollection will no longer work after a call to this cmdlets, unless their -Collection argument is provided or a new call to Connect-TfsTeamProjectCollection is made.

.EXAMPLE

	Disconnect-TfsTeamProjectCollection

	Disconnects from the currently connected TFS Team Project Collection

#>
Function Disconnect-TfsTeamProjectCollection
{
	Process
	{
		Remove-Variable -Name TfsTpcConnection -Scope Global
		Remove-Variable -Name TfsTpcConnectionUrl -Scope Global
		Remove-Variable -Name TfsTpcConnectionCredential -Scope Global
		Remove-Variable -Name TfsTpcConnectionUseDefaultCredentials -Scope Global
	}
}

<#
.SYNOPSIS

	Gets a TFS Team Project Collection.

.DESCRIPTION

	The Get-TfsTeamProject cmdlets gets one or more Team Project Collection objects (an instance of Microsoft.TeamFoundation.Client.TfsTeamProjectCollection) from a TFS instance. 
	
	Team Project Collection objects can either be obtained by providing a fully-qualified URL to the collection or by collection name (which requires a TFS Configuration Server to be supplied).

.PARAMETER Collection

	Specifies either a URL/name of the Team Project Collection to connect to, or a previously initialized TfsTeamProjectCollection object. 

	When using a URL, it must be fully qualified. The format of this string is as follows:

	http[s]://<ComputerName>:<Port>/[<TFS-vDir>/]<CollectionName>

	Valid values for the Transport segment of the URI are HTTP and HTTPS. If you specify a connection URI with a Transport segment, but do not specify a port, the session is created with standards ports: 80 for HTTP and 443 for HTTPS.

	To connect to a Team Project Collection by using its name, a TfsConfigurationServer object must be supplied either via -Server argument or via a previous call to the Connect-TfsConfigurationServer cmdlet.

	Finally, if a TfsTeamProjectCollection object is provided via this argument, it will be used as the new default connection. This may be especially useful if you e.g. received a pre-initialized connection to a TFS collection via a call to an external library or API.

.PARAMETER Server

	Specifies either a URL/name of the Team Foundation Server configuration server (the "root" of a TFS installation) to connect to, or a previously initialized Microsoft.TeamFoundation.Client.TfsConfigurationServer object.

.PARAMETER Credential

	Specifies a user account that has permission to perform this action. The default is the current user.

	Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet. If you type a user name, you will be prompted for a password.

	To connect to Visual Studio Online you must enable Alternate Credentials for your user profile and supply that credential in this argument.

	For more information on Alternate Credentials for your Visual Studio Online account, please refer to https://msdn.microsoft.com/library/dd286572#setup_basic_auth.

.EXAMPLE

	Get-TfsTeamProjectCollection http://

.INPUTS

	Microsoft.TeamFoundation.Client.TfsConfigurationServer

.NOTES

	Cmdlets in the TfsCmdlets module that operate on a collection level require a TfsConfiguration object to be provided via the -Server argument. If absent, it will default to the connection opened by Connect-TfsConfigurationServer.
#>
Function Get-TfsTeamProjectCollection
{
	[CmdletBinding()]
	[OutputType([Microsoft.TeamFoundation.Client.TfsTeamProjectCollection])]
	Param
	(
		[Parameter(Position=0)]
		[object] 
		$Collection = "*",
	
		[Parameter(ValueFromPipeline=$true)]
		[object] 
		$Server,
	
		[Parameter()]
		[System.Management.Automation.Credential()]
		[System.Management.Automation.PSCredential]
		$Credential
	)

	Process
	{
		if ($Collection -is [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection])
		{
			return $Collection
		}

		if ($Collection -is [Uri])
		{
			return _GetCollectionFromUrl $Collection $Credential
		}

		if ($Collection -is [string])
		{
			if ([Uri]::IsWellFormedUriString($Collection, [UriKind]::Absolute))
			{
				return _GetCollectionFromUrl ([Uri] $Collection) $Server $Credential
			}

			if (-not [string]::IsNullOrWhiteSpace($Collection))
			{
				return _GetCollectionFromName $Collection $Server $Credential
			}

			$Collection = $null
		}

		if ($Collection -eq $null)
		{
			if ($Global:TfsTpcConnection)
			{
				return $Global:TfsTpcConnection
			}
		}

		throw "No TFS connection information available. Either supply a valid -Collection argument or use Connect-TfsTeamProjectCollection prior to invoking this cmdlet."
	}
}

<#
.SYNOPSIS

The synopsis goes here. This can be one line, or many.
.DESCRIPTION

The description is usually a longer, more detailed explanation of what the script or function does. Take as many lines as you need.
.PARAMETER computername

Here, the dotted keyword is followed by a single parameter name. Don't precede that with a hyphen. The following lines describe the purpose of the parameter:
.PARAMETER filePath

Provide a PARAMETER section for each parameter that your script or function accepts.
.EXAMPLE

There's no need to number your examples.
.EXAMPLE
PowerShell will number them for you when it displays your help text to a user.
#>
Function Get-TfsRegisteredTeamProjectCollection
{
	[CmdletBinding()]
	[OutputType([Microsoft.TeamFoundation.Client.RegisteredProjectCollection[]])]
	Param
	(
		[Parameter(Position=0, ValueFromPipeline=$true)]
		[string]
		$Name = "*"
	)

	Process
	{
		return [Microsoft.TeamFoundation.Client.RegisteredTfsConnections]::GetProjectCollections() | ? DisplayName -Like $Name
	}
}

# =================
# Helper Functions
# =================

Function _GetCollectionFromUrl
{
	Param ($Url, $Cred)
	
	if ($Cred)
	{
		$tpc = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection -ArgumentList $Url, (_GetCredential $cred)
	}
	else
	{
		$tpc = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection([Uri] $Url)
	}

	return $tpc
}


Function _GetCollectionFromName
{
	Param
	(
		$Name, $Server, $Cred
	)
	Process
	{
		$configServer = Get-TfsConfigurationServer $Server -Credential $Cred
		$filter = [Guid[]] @([Microsoft.TeamFoundation.Framework.Common.CatalogResourceTypes]::ProjectCollection)
		
		$collections = $configServer.CatalogNode.QueryChildren($filter, $false, [Microsoft.TeamFoundation.Framework.Common.CatalogQueryOptions]::IncludeParents) 
		$collections = $collections | Select -ExpandProperty Resource | ? DisplayName -like $Name

		if ($collections.Count -eq 0)
		{
			throw "Invalid or non-existent Team Project Collection(s): $Name"
		}

		foreach($tpc in $collections)
		{
			$collectionId = $tpc.Properties["InstanceId"]
			$tpc = $configServer.GetTeamProjectCollection($collectionId)
			$tpc.EnsureAuthenticated()

			$tpc
		}

	}
}

Function _GetCredential
{
	Param ($Cred)

	if ($Cred)
	{
		return [System.Net.NetworkCredential] $Cred
	}
	
	return [System.Net.CredentialCache]::DefaultNetworkCredentials
}