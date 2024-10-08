#! /bin/bash

LOG_FILE=/home/jovyan/startup.log
log_to_file () {
    echo "$1 (exit value: $?)" | tee -a $LOG_FILE
}
touch $LOG_FILE

# start of actual setup steps
echo "-------------" >> $LOG_FILE
date >> $LOG_FILE
log_to_file "Start setup"

# 1
tar -xf /tmp/tars/jhub-conf.tar -C /tmp
log_to_file "Copy jupyterhub config directory"

# 2
conda init bash
log_to_file "Initialize conda"

# 3
# Singleuser env is no longer baked into the image
echo 'source /home/jovyan/.bashrc' > /home/jovyan/.profile
#echo 'source /home/jovyan/.bashrc && conda activate singleuser' > /home/jovyan/.profile
log_to_file "Add conda activate to .profile"

# 4
cp -r /tmp/config/opalbanner /opt/conda/share/jupyter/labextensions
bash /tmp/config/init_banner.bash "$OPAL_BANNER_TEXT" "$OPAL_BANNER_COLOR"
log_to_file "Initialize banner extension"

# copy from gitsync mount so user-facing directories are not constantly updated
# 5
cp -r /opt/data/opal /home/jovyan/
log_to_file "Link directories to home"


# 7
cp -r /opt/data/weave /home/jovyan/
log_to_file "Link directories to home"

# 8
cp /opt/conf/conda_channel.yaml /home/jovyan/
log_to_file "copy conda_channel to home (allows for temporary user edits)"

# 9
cp /opt/conf/.condarc /home/jovyan/
log_to_file "copy condarc to home (allows for temporary user edits)"

# 10
# envsubst is pretty important here, so we need to make sure it's therePYTHON3=$(get_python_3 $PYTHON3 $PYTHON $(which python) $(which python3))
SUB=$(which envsubst)
if [[ -z "${SUB}" ]] ; then
    log_to_file "attempting install of missing envsubst command"
    pip install envsubst
fi
mkdir -p /home/jovyan/.metaflowconfig
#cat /tmp/config/metaflow_config.json > /home/jovyan/.metaflowconfig/config.json
envsubst < /tmp/config/metaflow_config.json > /home/jovyan/.metaflowconfig/config.json
log_to_file "Fill in metaflow config file"

## 9
#python /tmp/config/python_setup.py
#log_to_file "Custom python setup"

# 11
# need this for accessing servers running in individual singleusers
# This will likely fail without an internet connection
conda install -c conda-forge jupyter-server-proxy -y

# Start the singleuser server (has to be last)
/usr/local/bin/start-singleuser.sh
