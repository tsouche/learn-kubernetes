#!/bin/bash

# Shared cluster's token information
token_path="/vagrant/data_token_k8s"
ca_cert_hash_path="/vagrant/data_token_ca_cert_hash"


# Cleanup
rm -rf "${token_path}"
rm -rf "${ca_cert_hash_path}"
