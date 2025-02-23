#!/bin/bash
#
# gh_get_latest - retrieve the latest release of a Github repository release
#
# Usage: gh_get_latest [-i] [-l] [-L] [-o owner] [-p project]
#
# Filtering the returned JSON object from the API request with:
#
#   curl --silent "${API_URL}" | \
#     jq --raw-output '.assets | .[]?.browser_download_url'
#
# Provides us with the release assets' browser download urls.
# For example, the mpcplus project has the following release assets:
#
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus-pkgbuild-1.0.0-1.tar.gz
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus-v1.0.0r1-1-x86_64.pkg.tar.zst
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.amd64.deb
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.armhf.deb
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.el8.x86_64.rpm
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.fc36.x86_64.rpm
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.tgz
# .../${OWNER}/${PROJECT}/.../TAG/mpcplus_1.0.0-1.zip
#
# To select the desired platform asset, use one of the following filters
#
# Arch:
#   CURL_PIP_TO_JQ | grep "\.pkg\.tar\.zst"
# CentOS:
#   CURL_PIP_TO_JQ | grep "\.el.*x86_64\.rpm"
# Fedora:
#   CURL_PIP_TO_JQ | grep "\.fc.*x86_64\.rpm"
# Raspberry Pi OS:
#   CURL_PIP_TO_JQ | grep "\.armhf\.deb"
# Ubuntu:
#   CURL_PIP_TO_JQ | grep "\.amd64\.deb"

usage() {
  printf "\nUsage: gh_get_latest [-i] [-l] [-L] [-o owner] [-p project]"
  printf "\nWhere:"
  printf "\n\t-i indicates install downloaded package"
  printf "\n\t\tprints download url if no '-i' argument provided"
  printf "\n\t-l indicates list all release assets for the project"
  printf "\n\t-L indicates use the Gitlab API to access projects hosted on Gitlab"
  printf "\n\t-o owner specifies the Github repository owner"
  printf "\n\t\tdefault: doctorfree"
  printf "\n\t-p project specifies the Github repository name"
  printf "\n\t\tdefault: mpcplus\n"
  exit 1
}

install_package() {
  if [ "${debian}" ]
  then
    [ "${APT}" ] && sudo ${APT} install $1
  else
    if [ "${centos}" ] || [ "${fedora}" ]
    then
      [ "${DNF}" ] && sudo ${DNF} install $1
    else
      [ "${arch}" ] && sudo pacman -U $1
    fi
  fi
} 

arch=
centos=
debian=
fedora=
rpi=
ubuntu=
use_gitlab=
have_apt=`type -p apt`
have_aptget=`type -p apt-get`
have_dnf=`type -p dnf`
have_curl=`type -p curl`
have_jq=`type -p jq`
have_yum=`type -p yum`
mach=`uname -m`

INSTALL=
LISTALL=
OWNER=doctorfree
PROJECT=mpcplus
while getopts "ilLo:p:u" flag; do
    case $flag in
        i)
            INSTALL=1
            ;;
        l)
            LISTALL=1
            ;;
        L)
            use_gitlab=1
            ;;
        o)
            OWNER="$OPTARG"
            ;;
        p)
            PROJECT="$OPTARG"
            ;;
        u)
            usage
            ;;
    esac
done
shift $(( OPTIND - 1 ))

[ "${LISTALL}" ] && [ "${INSTALL}" ] && INSTALL=

if [ "${use_gitlab}" ]
then
  API_URL="https://gitlab.com/api/v4/projects/${OWNER}%2F${PROJECT}/releases"
else
  API_URL="https://api.github.com/repos/${OWNER}/${PROJECT}/releases/latest"
fi


if [ -f /etc/os-release ]
then
  . /etc/os-release
  [ "${ID}" == "debian" ] || [ "${ID_LIKE}" == "debian" ] && debian=1
  [ "${ID}" == "arch" ] && arch=1
  [ "${ID}" == "centos" ] && centos=1
  [ "${ID}" == "fedora" ] && fedora=1
else
  if [ -f /etc/arch-release ]
  then
	arch=1
  else
    case "${mach}" in
      arm*)
		debian=1
		rpi=1
        ;;
      x86*)
        if [ "${have_apt}" ]
        then
		  debian=1
		  ubuntu=1
        else
		  # CentOS or Fedora
          if [ -f /etc/fedora-release ]
          then
            fedora=1
          else
            if [ -f /etc/centos-release ]
            then
              centos=1
            else
              if [ "${have_dnf}" ] || [ "${have_yum}" ]
              then
                # Use Fedora RPM for all other rpm based systems
                fedora=1
              else
                echo "Unknown operating system distribution"
              fi
            fi
          fi
        fi
        ;;
      *)
        echo "Unknown machine architecture"
        ;;
    esac
  fi
fi

[ "${debian}" ] && {
  if [ "${have_apt}" ]
  then
    APT="apt -q -y"
  else
    if [ "${have_aptget}" ]
    then
      APT="apt-get -q -y"
    else
      echo "Could not locate apt or apt-get."
    fi
  fi
}

[ "${centos}" ] || [ "${fedora}" ] && {
  if [ "${have_dnf}" ]
  then
    DNF="dnf --assumeyes --quiet"
  else
    if [ "${have_yum}" ]
    then
      DNF="yum --assumeyes --quiet"
    else
      echo "Could not locate dnf or yum."
    fi
  fi
}

[ "${have_curl}" ] || install_package curl
[ "${have_jq}" ] || install_package jq

[ "${LISTALL}" ] && {
  if [ "${use_gitlab}" ]
  then
    curl --silent "${API_URL}" | \
         jq --raw-output '.[0].assets.links | .[]?.direct_asset_url'
  else
    curl --silent "${API_URL}" | \
         jq --raw-output '.assets | .[]?.browser_download_url'
  fi
  exit 0
}

DL_URL=
if [ "${arch}" ]
then
  if [ "${use_gitlab}" ]
  then
    DL_URL=$(curl --silent "${API_URL}" | \
           jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
           grep "\.pkg\.tar\.zst")
  else
    DL_URL=$(curl --silent "${API_URL}" | \
           jq --raw-output '.assets | .[]?.browser_download_url' | \
           grep "\.pkg\.tar\.zst")
  fi
else
  if [ "${centos}" ]
  then
    if [ "${use_gitlab}" ]
    then
      DL_URL=$(curl --silent "${API_URL}" | \
             jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
             grep "\.el.*x86_64\.rpm")
    else
      DL_URL=$(curl --silent "${API_URL}" | \
             jq --raw-output '.assets | .[]?.browser_download_url' | \
             grep "\.el.*x86_64\.rpm")
    fi
    [ "${DL_URL}" ] || {
      # Sometimes the project does not use an architecture suffix
      if [ "${use_gitlab}" ]
      then
        DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
               grep ".*\.rpm")
      else
        DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.assets | .[]?.browser_download_url' | \
               grep ".*\.rpm")
      fi
    }
  else
    if [ "${fedora}" ]
    then
      if [ "${use_gitlab}" ]
      then
        DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
               grep "\.fc.*x86_64\.rpm")
      else
        DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.assets | .[]?.browser_download_url' | \
               grep "\.fc.*x86_64\.rpm")
      fi
      [ "${DL_URL}" ] || {
        # Sometimes the project does not use an architecture suffix
        if [ "${use_gitlab}" ]
        then
          DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
               grep ".*\.rpm")
        else
          DL_URL=$(curl --silent "${API_URL}" | \
               jq --raw-output '.assets | .[]?.browser_download_url' | \
               grep ".*\.rpm")
        fi
      }
    else
      if [ "${debian}" ]
      then
        if [ "${mach}" == "x86_64" ]
        then
          if [ "${use_gitlab}" ]
          then
            DL_URL=$(curl --silent "${API_URL}" | \
                   jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
                   grep "\.amd64\.deb")
          else
            DL_URL=$(curl --silent "${API_URL}" | \
                   jq --raw-output '.assets | .[]?.browser_download_url' | \
                   grep "\.amd64\.deb")
          fi
          [ "${DL_URL}" ] || {
            # Sometimes the project does not use an architecture suffix
            if [ "${use_gitlab}" ]
            then
              DL_URL=$(curl --silent "${API_URL}" | \
                jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
                grep ".*\.deb")
            else
              DL_URL=$(curl --silent "${API_URL}" | \
                jq --raw-output '.assets | .[]?.browser_download_url' | \
                grep ".*\.deb")
            fi
          }
        else
          if [ "${use_gitlab}" ]
          then
            DL_URL=$(curl --silent "${API_URL}" | \
                   jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
                   grep "\.arm.*\.deb")
          else
            DL_URL=$(curl --silent "${API_URL}" | \
                   jq --raw-output '.assets | .[]?.browser_download_url' | \
                   grep "\.arm.*\.deb")
          fi
          [ "${DL_URL}" ] || {
            # Sometimes the project does not use an architecture suffix
            if [ "${use_gitlab}" ]
            then
              DL_URL=$(curl --silent "${API_URL}" | \
                jq --raw-output '.[0].assets.links | .[]?.direct_asset_url' | \
                grep ".*\.deb")
            else
              DL_URL=$(curl --silent "${API_URL}" | \
                jq --raw-output '.assets | .[]?.browser_download_url' | \
                grep ".*\.deb")
            fi
          }
        fi
      else
        echo "No release asset found for this platform"
      fi
    fi
  fi
fi

if [ "${DL_URL}" ]
then
  if [ "${INSTALL}" ]
  then
    printf "\n\tAttempting to install the '${PROJECT}' release asset ..."
    if [ "${debian}" ]
    then
      have_wget=`type -p wget`
      [ "${have_wget}" ] || {
        [ "${APT}" ] && sudo ${APT} install wget
      }
      TEMP_DEB="$(mktemp)"
      wget --quiet -O "${TEMP_DEB}" "${DL_URL}"
      [ "${APT}" ] && sudo ${APT} install "${TEMP_DEB}"
      rm -f "${TEMP_DEB}"
    else
      if [ "${centos}" ] || [ "${fedora}" ]
      then
        [ "${DNF}" ] && sudo ${DNF} install ${DL_URL}
      else
        [ "${arch}" ] && sudo pacman -U ${DL_URL}
      fi
    fi
  else
    printf "${DL_URL}\n"
  fi
else
  exit 1
fi
