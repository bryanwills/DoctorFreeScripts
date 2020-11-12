#!/bin/bash

project="Cryptocurrency"
patch="${project}-patch.tgz"

[ -d ${project} ] && {
    rm -rf ${project}
}

git clone ssh://gitlab.com/doctorfree/Cryptocurrency.git

[ -r ${patch} ] && tar xzvf ${patch}
