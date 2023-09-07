#!/bin/bash

function valid_ip()
{
    local  IPA1=$1
    local  stat=1

    if [[ $IPA1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
    then
        OIFS=$IFS # Save the actual IFS in a var named OIFS
        IFS='.'   # IFS (Internal Field Separator) set to .
        ip=($ip)  # ¿Converts $ip into an array saving ip fields on it?
        IFS=$OIFS # Restore the old IFS

        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]  # If $ip[0], $ip[1], $ip[2] and $ip[3] are minor or equal than 255 then

        stat=$? # $stat is equal to TRUE if is a valid IP or FALSE if it isn't

    fi # End if

    return $stat  # Returns $stat
}

az --version

az login --service-principal -u $APP_ID -p $APP_PASSWORD --tenant $APP_TENANT_ID
#az login --identity

sleep 3s

ACI_IP=$(az container show --name $ACI_INSTANCE_NAME --resource-group $RESOURCE_GROUP --query ipAddress.ip --output tsv)

echo $ACI_IP

current_dns_ip=$(az network private-dns record-set a show --name $A_RECORD_NAME --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME --query aRecords[0].ipv4Address| xargs)

echo $current_dns_ip

if [ "$current_dns_ip" = "$ACI_IP" ] ; then
    echo "Not changing"
else
    r=$(valid_ip $current_dns_ip)
    if [ $? -eq "0" ] ; then
        echo "Updating"
        az network private-dns record-set a update --name $A_RECORD_NAME --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME --set aRecords[0].ipv4Address=$ACI_IP
    else
        echo "Adding"
        az network private-dns record-set a create -n $A_RECORD_NAME -g $RESOURCE_GROUP  -z $DNS_ZONE_NAME
        az network private-dns record-set a add-record -n $A_RECORD_NAME -g $RESOURCE_GROUP -z $DNS_ZONE_NAME --ipv4-address $ACI_IP
    fi
fi

echo "Done"
