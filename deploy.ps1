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
