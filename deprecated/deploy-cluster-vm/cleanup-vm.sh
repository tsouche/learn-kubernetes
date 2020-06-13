#!/bin/bash

echo " "
echo "======================================================================="
echo "|  Delete the cluster and clean temporary files                       |"
echo "======================================================================="
echo " "

echo "..."
echo " Remove the cluster"
echo "..."
echo " "

vagrant destroy

echo "..."
echo " Remove temporary files"
echo "..."
echo " "

rm -rf ~/.kube
rm -rf ./.kube
rm -rf ./.vagrant
rm -rf ./temp*

echo "======================================================================="
echo " The END"
echo "======================================================================="
echo " "
