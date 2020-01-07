#!/bin/bash

echo "========================================================================"
echo "|  Cleanup after the Kubernetes tutorial                               |"
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
    echo "This script will cleanup after having deployed a 3-nodes Kubernetes"
    echo "cluster. You must indicate the type of deployment you want:"
    echo "    ./cleanup.sh 'argument'"
    echo "where 'argument is:"
    echo "    -c, --containers         it will deploy the cluster on containers"
    echo "    -v, --virtualmachines    it will deploy the cluster on VMs"
    echo " "
    echo "Please retry with one of these arguments."
}   # end of help_message


# set the right value for 'argument' based on the arguments passed
if [ "$1" != "" ]
then
    case $1 in
        -c | --containers )      cd ./deploy-cluster-cont/
                                 ./cleanup-cont.sh
                                 cd ..
                                 ;;
        -v | -virtualmachines )  cd ./deploy-cluster-vm/
                                 ./cleanup-vm.sh
                                 cd ..
                                 ;;
        -h | --help )            help_message
                                 ;;
    esac
else
    help_message
fi
    

    
echo " "
echo "========================================================================"
echo "|  The END                                                             |"
echo "========================================================================"
