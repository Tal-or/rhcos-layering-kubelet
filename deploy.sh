#!/bin/sh

#
# Configure the variable below to point to an image registry
# you have push permissions for and that will be accessible
# from the cluster
REGISTRY_IMAGE=quay.io/msivak/test-build:rhcos-layer-2

#
# Configure the MachineConfig label needed to targed the proper
# MachineConfigPool
MCLABEL="machineconfiguration.openshift.io/role: worker-cnf"

#
# Find the proper RHCOS base image for building the override
# layer
# Either use:
#   oc adm release info --image-for=rhel-coreos 4.16.ZZ
# Or as a developer do:
# 1. Go to https://amd64.ocp.releases.ci.openshift.org/releasestream/4-stable and click on the wanted OCP release
# 2. Wait for the changelog to load at the bottom of the page
# 3. find Changes from / Changes / Components / Red Hat Enterprise Linux CoreOS upgraded from (A) to (B)
# 4. Click (B) which will take you to the RHCOS release details page
# 5. Copy the RHCOS Base OS url to the FROM below
FROM="quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:da4c28471c05718a1e90879d5d932a9054a0e2e4248255bb079c58a3c13e58fe"

### Do not change below this line

# Configure Containerfile
sed -e "s|^FROM quay.io/openshift-release.*$|FROM ${FROM}|" Containerfile.orig > Containerfile

# Build the layer
podman build --no-cache -t ${REGISTRY_IMAGE} .
podman push ${REGISTRY_IMAGE}

# Configure the MachineConfig
sed -e "s|machineconfiguration.openshift.io/role.*|${MCLABEL}|" -e "s|osImageURL:.*|osImageURL: ${REGISTRY_IMAGE}|" mc-layer.yaml.orig  > mc-layer.yaml

# Apply the MC to the cluster
# oc apply -f mc-layer.yaml

