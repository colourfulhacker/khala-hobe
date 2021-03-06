#
#########################Cehpoint###################################################################################################################################################################

#!/bin/bash

function usage {
	echo "usage: $1 [-d domain]"
}
domain=""

while getopts "d:" OPT; do
	case $OPT in
		d) domain=$OPTARG;;
		*) usage $0; exit;;
	esac
done

if [ ! -d ./output ]; then
	  mkdir ./output
	  mkdir ./output/whois
	  mkdir ./output/hostsearch
	  mkdir ./output/dnslookup
	  mkdir ./output/dnsenum
	  mkdir ./output/domain
	  mkdir ./output/recon-ng-out
	  mkdir ./output/harvester
	  mkdir ./output/dnstwist
fi

###Perform check if $domain is populated
if [[ -z $domain ]]; then 
	usage $0;
	exit;
fi

stamp=$(date +"%m_%d_%Y")

###Perform Whois of the Domain
if [ ! -f ./output/whois/whois.$domain ]; then
	echo "[+] Performing whois"
	whois -H $domain > ./output/whois/whois.$domain
else 
	echo "[+] whois results present"
fi

if [ ! -f ./output/hostsearch/hostsearch.$domain ]; then
###Perform hostsearch via DNS Dumpster API
	echo "[+] Performing DNS Dumpster"
	curl -s http://api.hackertarget.com/hostsearch/?q=$domain > ./output/hostsearch/hostsearch.$domain

##Creating hostsearch output consistent as recon-ng output
	cat ./output/hostsearch/hostsearch.$domain | awk -F , '{print "\""$1"\""",""\""$2"\""}' > ./output/hostsearch/hostsearch.temp
	awk -F, '{$(NF+1)="X" FS "X" FS "X" FS "X" FS "hostsearch";}1' OFS=, ./output/hostsearch/hostsearch.temp > ./output/hostsearch/hostsearch.$domain.csv
#	rm ./output/hostsearch/hostsearch.temp
else
	echo "[+] DNS Dumpster results present"
fi

if [ ! -f ./output/dnslookup/dnslookup.$domain ]; then
###Perform DNS queries
	echo "[+] Performing DNS Queries"
	curl -s http://api.hackertarget.com/dnslookup/?q=$domain > ./output/dnslookup/dnslookup.$domain
else
	echo "[+] DNS Queries Results present"
fi

##Performing Recon-ng enumall.sh
### You might want to change the file saving location
if [ ! -f ./output/recon-ng-out/recon-ng.$domain.csv ]; then
	echo "[+] Performing Recon-ng queries"
	/opt/domain/enumall.sh $domain
	cp /tmp/$domain$stamp.csv ./output/recon-ng-out/recon-ng.$domain.csv
else
	echo "[+] Recon-ng results present"
fi


###Run harvestor
if [ ! -f ./output/harvester/harvester.$domain.out ]; then
	echo "[+] Performing theharvester"
	theharvester -d $domain -b all -f ./output/harvester/harvester.$domain > ./output/harvester/harvester.$domain.out
else
	echo "[+] theharvester results present"
fi

###DNS Enum
if [ ! -f ./output/dnsenum/dnsenum.$domain ]; then
	echo "[+] Performing DNSenum queries"
	dnsenum -o ./output/dnsenum/dnsenum.$domain.xml $domain > ./output/dnsenum/dnsenum.$domain
else
	echo "[+] dnsenum results present"
fi

###DNS Twist
if [ ! -f ./output/dnstwist/dnstwist.$domain ]; then
	echo "[+] Performing DNStwist queries"
	python /opt/dnstwist/dnstwist.py -c -r $domain > ./output/dnstwist/dnstwist.$domain
else
	echo "[+] DNSTwist results present"
fi


##Copying hostsearch via DNS Dumpster API to final output
	cp ./output/hostsearch/hostsearch.$domain.csv ./output/final_output.csv

#Adding , to the end of final_output
	sed -i -e "s/$/,/" ./output/final_output.csv 

###Copying data from theharvester between Resolving to virtual to final_output.csv
	sed -n "/Resolving/,/Virtual/{/Resolving/b;/Virtual/b;p}" ./output/harvester/harvester.$domain.out | awk -F : '{print "\"" $2 "\",\"" $1"\""}' >> ./output/harvester/harvester.rv.$domain
	awk -F, '{$(NF+1)="X" FS "X" FS "X" FS "X" FS "harvester";}1' OFS=, ./output/harvester/harvester.rv.$domain > ./output/harvester/harvester.temp2
	cat ./output/harvester/harvester.temp2 >> ./output/final_output.csv
#	rm ./output/harvester/harvester.temp
	rm ./output/harvester/harvester.temp2

###Copying data from theharvester between Virtual to Saving to final_output.csv
	sed -n "/Virtual/,/Saving/{/Virtual/b;/Saving/b;p}" ./output/harvester/harvester.$domain.out | awk '{print "\"" $2 "\",\"" $1"\""}' >> ./output/harvester/harvester.vs.$domain
	awk -F, '{$(NF+1)="X" FS "X" FS "X" FS "X" FS "harvester_virtual_host";}1' OFS=, ./output/harvester/harvester.vs.$domain > ./output/harvester/harvester.temp2
	cat ./output/harvester/harvester.temp2 >> ./output/final_output.csv
	rm ./output/harvester/harvester.temp
	rm ./output/harvester/harvester.temp2

###Running dnstwist on the domain and getting probable typo domains registered
	cat ./output/dnstwist/dnstwist.$domain | cut -d , -f2-3 | grep -v domain-name > ./output/dnstwist/dnstwist.temp
	awk -F, '{$(NF+1)="X" FS "X" FS "X" FS "X" FS "dnstwist";}1' OFS=, ./output/dnstwist/dnstwist.temp > ./output/dnstwist/dnstwist.temp2
	cat ./output/dnstwist/dnstwist.temp2 >> ./output/final_output.csv
	

###Copying data from theharvester between Email to Hosts and saving it to email_output.csv
	sed -n "/Emails/,/Hosts/{/Email/b;/Hosts/b;p}" ./output/harvester/harvester.$domain.out | grep -v "-" | awk '{print "\"" $1 "\""}' >> ./output/domain/emails_$domain.csv

###Appending the data generated from recon-ng to final_output.csv
	cat ./output/recon-ng-out/recon-ng.$domain.csv >> ./output/final_output.csv 

###Adding the domainname in the final_output.csv on the first coloum
	awk -v var="$domain" -F, '{$1=var FS $1;}1' OFS=, ./output/final_output.csv > ./output/final_output2.csv

###Get the final output
	cat ./output/final_output2.csv | cut -d , -f1- | grep -v = | sort | uniq > ./output/domain/final_$domain.csv
	echo "The result are stored in ./output/domain/final_$domain.csv"

	echo "[+] dnsenum results present"
	echo "The result are stored in ./output/domain/final_$domain.csv"
