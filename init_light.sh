#!/bin/bash

pip3 install --requirement requirements.txt || exit 1
PATH="/usr/local/bin:$(python3 -m site --user-base)/bin:$PATH"
export PATH
ansible-galaxy install -r requirements.yml || exit 1
