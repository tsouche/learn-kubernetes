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

rm -rf ./.vagrant

echo "======================================================================="
echo " The END"
echo "======================================================================="
echo " "
