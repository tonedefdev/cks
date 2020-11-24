param(
    [switch]$CreateIngress,
    [switch]$DestroyCluster,
    [switch]$StartDocker
)

$greenCheck = @{
    Object = [char]8730
    ForegroundColor = "Green"
    NoNewLine = $true
}

$redHeart = @{
    Object = ([char]9829)
    ForegroundColor = "Red"
    NoNewLine = $true
}

$cyanGear = @{
    Object = ([char]9788)
    ForegroundColor = "Cyan"
    NoNewLine = $true 
}

$lightning = @{
    Object = ([char]9889)
    NoNewLine = $true
}

$sunny = @{
    Object = ([char]9925)
    NoNewLine = $true
}

$destroy = @{
    Object = ([char]9940)
    NoNewLine = $true
}

if ($destroyCluster.IsPresent)
{
    Write-Host "Destroying cluster 'kind' ..."
    Write-Host " " -NoNewline
    Write-Host @destroy
    Write-Host " Waiting for cluster to destroy " -NoNewline
    Invoke-Expression "kind delete cluster" 2>&1>$null
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host @greenCheck
        Write-Host "Cluster was successfully destroyed!"
    }

    return $null
}

if ($startDocker.IsPresent)
{
    Invoke-Expression -Command "& 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
    Write-Host "Starting Docker Desktop ..."
    Write-Host " " -NoNewline
    Write-Host @greenCheck
    Write-Host " Waiting for VM to start and Docker to be ready " -NoNewline
    $dockerStarted = $false
    while (-not $dockerStarted)
    {
        Invoke-Expression -Command "docker ps" 2>&1>$null
        if ($LASTEXITCODE -eq 0)
        {
            $dockerStarted = $true
        }
        Start-Sleep -Seconds 10
    }
    Write-Host @redHeart
    Write-Host "`n"
}

Invoke-Expression -Command "kind create cluster --config $PSScriptRoot\kind-config.yaml"

Write-Host "Setting up networking components ..."
Write-Host " " -NoNewline
Write-Host @greenCheck
Write-Host " Deploying Calico CNI " -NoNewline
Invoke-Expression -Command "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml" 2>&1>$null
Invoke-Expression -Command "kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true" 2>&1>$null
Write-Host @lightning

if ($createIngress.IsPresent)
{
    Write-Host " "
    Write-Host " " -NoNewline
    Write-Host @greenCheck
    Write-Host " Deploying Helm chart 'kind-ingress-nginx' " -NoNewline
    Invoke-Expression -Command "helm install kind-ingress-nginx $PSScriptRoot\kind-ingress-nginx-0.1.0.tgz --namespace=ingress-nginx --create-namespace" 2>&1>$null
    Write-Host @cyanGear
}

Write-Host " "
Write-Host " " -NoNewline
Write-Host @greenCheck
Write-Host " The cluster is ready for your CKS studies. Happy Hacking! " -NoNewline
Write-Host @sunny
Write-Host "`n"

Set-Alias -Name k -Value kubectl