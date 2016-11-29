#!/bin/bash

mysql -u ottol -p'e^?0aI/%' 2>>/home/ottol/mysql_Scripts/showDatabases.err <<EOF
show databases
EOF
