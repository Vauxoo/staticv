#!/bin/sh
############################################################################################
# Installer for StaticV, always will download the latest version                           #
############################################################################################
set -e

get_arch() {
  arch=$(uname -m)
  case $arch in
    x86_64) arch="amd64" ;;
    x86) arch="386" ;;
  esac
  echo ${arch}
}

download_url() {
    api_url=$1
    url_for=$2
    wget -q -O- ${api_url}  | jq -r '.assets[].browser_download_url' | grep ${url_for}
}

get_filename() {
    api_url=$1
    url_for=$2
    wget -q -O- ${api_url}  | jq -r '.assets[].name' | grep ${url_for}
}


release_version() {
    api_url=$1
    wget -q -O- ${api_url}  | jq -r '.tag_name'
}

check_sha() {
    org=$1
    expected=$2

    current=$(sha256sum $1 | cut -d ' ' -f 1)
    if [ "$expected" != "$current" ]; then
        echo "failed sha256sum for '$org', ${expected} vs ${current} don't match"
        return 1
    fi
}

BINARY=staticv
FORMAT=tar.gz
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(get_arch)
API_URL=https://api.github.com/repos/Vauxoo/${BINARY}/releases/latest
URL=$(download_url ${API_URL} ${OS}_${ARCH})
CHECKSUMS=$(download_url ${API_URL} checksums.txt)
TEMP=$(mktemp -d)
SUMSLOCAL=${TEMP}/checksums.txt
TAG=$(release_version ${API_URL})
FULLNAME=$(get_filename ${API_URL} ${OS}_${ARCH})


download() {
    url=$1
    dest=$2
    wget -q -O ${dest} "${url}"
}

echo "Version ${TAG} will be installed"
echo "Downloading binaries..."
download ${URL} ${TEMP}/${FULLNAME}
download ${CHECKSUMS} ${SUMSLOCAL}
# Check sha256 sum
echo "Cheking sha of the file"
sha=$(grep "${FULLNAME}" "${SUMSLOCAL}" 2>/dev/null | tr '\t' ' ' | cut -d ' ' -f 1)
check_sha ${TEMP}/${FULLNAME} $sha

echo "Decompressing and installing"
(cd "${TEMP}" && tar --no-same-owner -xzf "${FULLNAME}" && mv ${BINARY} /usr/bin)

rm -r ${TEMP}

echo "Done"
