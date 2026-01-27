#!/bin/bash
pwd
pushd ../terraform
terraform init -upgrade=false
terraform plan
terraform apply --auto-approve


popd 

pwd
