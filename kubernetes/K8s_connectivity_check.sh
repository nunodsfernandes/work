#!/bin/bash

# Root check
[ "$(whoami)" != 'root' ] && ( echo "This script MUST be run as root" ; exit 1 )

# Color definitions
    RED="\e[1;31m"
    GREEN="\e[1;32m"
    BLUE="\e[1;34m"
    YELLOW="\e[1;33m"
    PURPLE="\e[1;35m"
    NC="\e[0m" # No Color


show_spinner()
{
  local -r pid="${1}"
  local -r delay='0.75'
  local spinstr='\|/-'
  local temp
  while ps a | awk '{print $1}' | grep -q "${pid}"; do
    temp="${spinstr#?}"
    printf " [%c]  " "${spinstr}"
    spinstr=${temp}${spinstr%"${temp}"}
    sleep "${delay}"
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}


#************ FUNCTIONS




function check_connectivity() {

    countconnectcheck=$((countconnectcheck+1))

    if [[ $(timeout 10s curl -s $1) ]]; then
      echo -e "${GREEN}PASS${NC}| $2"
        accesstracking=$((accesstracking+1))
    else
      echo -e "${RED}FAIL${NC}| $2"
        accesstracking=$((accesstracking-1))
        accessfailcount=$((accessfailcount+1))
    fi
}

function check_proxy() {
    if [[ $(env | grep proxy) ]]; then
    env | grep proxy
    else
    echo -e "No proxies defined on the environment variables."
    fi
}

function check_ifconfig {
    if [[ $(timeout 5s curl -s curl ifconfig.me) ]]; then
      pub_ip_outside=$(timeout 5s curl -s ifconfig.me)
    else
      pub_ip_outside="None"
    fi
}



#************ CHECKS
# Clear all vars and screen
CONNECT_CHECK=""
PROXYDEFINED=""
pub_ip_outside=""
cansetup=""
countconnectcheck=0
accessfailcount=0
accesstracking=0

clear

#Start the checks
printf " ${RED} -----:)  EO CONNECTIVITY TEST  SUITE  (:----- ${NC} \n"
echo ""
echo ""

printf " ${YELLOW} *** NETWORK INTERFACES *** ${NC} \n"
# Place all the adapters on an array:
  network_adapters_on_machine=()
    while IFS= read -r line; do
       network_adapters_on_machine+=( "$line" )
    done < <( ip -br -c addr show | egrep -v DOWN | egrep -v UNKNOWN | cut -f1 -d"/" )

# Print the array on screen - Select single value by changing the "@" for the array  component number
printf '%s\n' "${network_adapters_on_machine[@]}"

echo ""
echo ""

# Check for internet connectivity by looking at Google and getting the external IP for the machine
printf " ${YELLOW} *** INTERNET CONNECTIVITY *** ${NC} \n"
check_ifconfig
printf "${PURPLE}Public IP: ${NC} %s \n" $pub_ip_outside
check_connectivity google.com "Google.com"

echo ""
echo ""

printf " ${YELLOW} *** REPOSITORIES (HTTPS check) *** ${NC} \n"
# Check for connectivity by: function address "description"

check_connectivity https://aws.amazon.com "Amazon Web Services"
check_connectivity https://github.com "GitHub (public)"
check_connectivity https://cloud.google.com "Google Cloud Container Registry"
check_connectivity https://www.docker.elastic.co "Docker Elastic"
check_connectivity https://k8s.gcr.io "K8s GCR"
check_connectivity https://quay.io "Quay.io"

echo ""
echo ""

printf " ${YELLOW} *** ENVIRONMENT PROXY SETTINGS *** ${NC} \n"
# Check for the environment variables
check_proxy

echo ""
echo ""


# Counter vs Access check:
if [ "$countconnectcheck" = "$accesstracking" ]; then
   printf "${GREEN} %s TESTS COMPLETED. CONNECTIVITY IS OK. ${NC} \n" $accesstracking
   echo ""
   echo ""
   cansetup=1
else
   printf "${RED} %s TESTS FAILED. CONNECTIVITY IS NOT OK! ${NC} \n" $accessfailcount
   echo "Please check connectivity before setting up the K8s stack."
   echo ""
   cansetup=0
fi
