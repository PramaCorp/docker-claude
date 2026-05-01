#!/bin/sh


# this is all iceing. 
# it makes ls -l show the right user/group for the current user
# Define a temporary passwd file in a writable location
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/tmp/group
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnss_wrapper.so

user=${USER:-node}

# Copy existing entries and add ourselves
cp /etc/passwd $NSS_WRAPPER_PASSWD
echo "$user:x:$(id -u):$(id -g):$user:/home/node:/bin/sh" >> $NSS_WRAPPER_PASSWD

cp /etc/group $NSS_WRAPPER_GROUP
echo "$user:x:$(id -g):" >> $NSS_WRAPPER_GROUP



# this is the magic
# when docker is launched with --user the container looks that stuff up in
# /etc/passwd and since if it's not there (usually) HOME is set to / that sends
# claude into a loop on startup trying to find the config files
export HOME=/home/node

exec "$@"
