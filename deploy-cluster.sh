#!/bin/bash

echo "========================================================================"
echo "|  Deploy a 3 nodes Kubernetes cluster                                 |"
echo "========================================================================"
echo " "

# The script will take one argument. The possible values are:
#
#   -h or --help    it will display a short explanation
#   kind            it will deploy a cluster on docker containers, using kind
#   vm              it will deploy a cluster on VMs, using Vagrant
#
# Any other argument will stop the execution.

# Reminder:
# $0 = the shell script name itself
# $1 = the expected argument


help_message()
{
    # display the help message
    echo "This script will deploy a 3-nodes Kubernetes cluster. You must indicate"
    echo "the type of deployment you want:"
    echo "   deploy-cluster 'argument'"
    echo "where 'argument is:"
    echo "   -k --kind     it will deploy the cluster on docker containers"
    echo "   -v --vm       it will deploy the cluster on VMs"
    echo " "
    echo "Please retry with one of these arguments."
}   # end of help_message


# set the right value for 'argument' based on the arguments passed
if [ "$1" != "" ]
then
    case $1 in
        -k | --kind )       cd ./deploy-cluster-kind/
                            ./deploy-kind.sh
                            cd ..
                            ;;
        -v | -vm )          cd ./deploy-cluster-vm/
                            ./deploy-vm.sh
                            cd ..
                            ;;
        -h | --help )       help_message
                            ;;
    esac
else
    help_message
fi
    

    
echo " "
echo "========================================================================"
echo "|  The END                                                             |"
echo "========================================================================"
