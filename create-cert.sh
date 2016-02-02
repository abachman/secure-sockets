#!/bin/bash

ts=`date +%F-%T | sed 's/:/-/g'`

# this version will NOT ask you to create a passphrase
openssl req -x509 -nodes -newkey rsa:2048 -keyout cert/key_$ts.pem -out cert/cert_$ts.pem -days 2048

# this version will ask you to create a passphrase
# openssl req -x509 -newkey rsa:2048 -keyout cert/key_$ts.secure.pem -out cert/cert_$ts.pem -days 2048
