#!/bin/bash

project="DoctorFreeScripts"
patch="${project}-patch.tgz"

[ -d ${project} ] && {
    rm -rf ${project}
}

git clone ssh://gitlab.com/doctorfree/DoctorFreeScripts.git

[ -r ${patch} ] && tar xzvf ${patch}
