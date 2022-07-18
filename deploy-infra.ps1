# Define zone name and add it to the DNS
$Zone="ocp-aro.mycustomdomain.io"
Add-DnsServerPrimaryZone -Name $Zone -ZoneFile ($Zone + ".dns")

# Define RG and Cluster name
$ARO_RG = "ARO"
$ARO_NAME = "ARO"

# Create RG
az group create --location canadacentral --resource-group $ARO_RG

# Create VNet
az network vnet create -g $ARO_RG -n vnet-aro --address-prefixes 10.0.0.0/16

# Create two subnets
az network vnet subnet create -g $ARO_RG --vnet-name vnet-aro -n "subnet-control" --address-prefixes 10.0.0.0/23
az network vnet subnet create -g $ARO_RG --vnet-name vnet-aro -n "subnet-worker" --address-prefixes 10.0.2.0/23

# Disable link service network policies
az network vnet subnet update -g $ARO_RG --vnet-name vnet-aro -n "subnet-control" --disable-private-link-service-network-policies true
az network vnet subnet update -g $ARO_RG --vnet-name vnet-aro -n "subnet-worker" --disable-private-link-service-network-policies true

# Create ARO
az aro create --resource-group $ARO_RG --name $ARO_NAME --vnet vnet-aro --master-subnet subnet-control --worker-subnet subnet-worker --domain $Zone --pull-secret "@$Home\Downloads\secret.txt"

# Query and save endpoints
az aro show -n $ARO_NAME -g $ARO_RG --query '{api:apiserverProfile.ip, ingress:ingressProfile[0].ip}'
$API_IP = (az aro show -n $ARO_NAME -g $ARO_RG --query '{api:apiserverProfile.ip}' -o tsv)
$INGRESS_IP = (az aro show -n $ARO_NAME -g $ARO_RG -- '{ingress:ingressProfile[0].ip}' -o tsv)

# Create DNS records
Add-DnsServerResourceRecordA -IPv4Address $API_IP -ZoneName $Zone -Name "api"
Add-DnsServerResourceRecordA -IPv4Address $INGRESS_IP -ZoneName $Zone -Name ".apps"

# Show resources
Start-Process ("https://portal.azure.com/#@" + (az account show --query tenantId -o tsv) + "/resource" + (az group show -n $ARO_RG --query id -o tsv))
az aro show -n $ARO_NAME -g $ARO_RG --query clusterProfile
Start-Process ("https://portal.azure.com/#@" + (az account show --query tenantId -o tsv) + "/resource" + (az aro show -n $ARO_NAME -g $ARO_RG --query clusterProfile))