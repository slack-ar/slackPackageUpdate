#!/bin/bash

# Script to automate the process of updating packages in Slackware

# Define the Slackware version
SLACK_VER="14.2"

# Define the Slackware package repository
SLACK_REPO="https://mirrors.slackware.com/slackware/slackware${SLACK_VER}/patches/packages"

# Define the Slackware package list file
SLACK_PKG_LIST="slackware${SLACK_VER}-packages.txt"

# Download the latest package list from the Slackware repository
wget "${SLACK_REPO}/${SLACK_PKG_LIST}"

# Check if the package list was downloaded successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to download the Slackware package list."
  exit 1
fi

# Read the package list file line by line
while read -r line; do
  # Skip lines that start with "#" (comments)
  if [[ "$line" =~ ^#.* ]]; then
    continue
  fi

  # Split the line into package name and version
  pkg_name=$(echo "$line" | awk '{print $1}')
  pkg_version=$(echo "$line" | awk '{print $2}')

  # Check if the package is already installed
  pkg_installed=$(ls /var/log/packages | grep "^${pkg_name}-[0-9]" | head -1)
  if [ -z "$pkg_installed" ]; then
    # Package is not installed, skip to next line
    continue
  fi

  # Compare the installed package version with the latest version
  if [ "$pkg_installed" == "${pkg_name}-${pkg_version}" ]; then
    # Package is already up to date, skip to next line
    continue
  fi

  # Package needs to be updated, download the latest package
  wget "${SLACK_REPO}/${pkg_name}-${pkg_version}.txz"

  # Check if the package was downloaded successfully
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download the package ${pkg_name}-${pkg_version}."
    exit 1
  fi

  # Install the latest package
  installpkg "${pkg_name}-${pkg_version}.txz"

  # Check if the package was installed successfully
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install the package ${pkg_name}-${pkg_version}."
    exit 1
  fi

  # Package was successfully updated, print a message
  echo "Package ${pkg_name} was successfully updated to version ${pkg_version}."
done < "$SLACK_PKG_LIST"

# Clean up the package list file
rm "$SLACK_PKG_LIST"
