#!/usr/bin/env sh

nginx_channel="/nginx-share/condapkg"
local_channel="/home/jovyan/local-channel"


checksum_diff(){
    if [[ -f "$nginx_channel/$1" ]]; then

        local_md5=($(md5sum "$local_channel/$1"))
        remote_md5=($(md5sum "$nginx_channel/$1"))

        if [[ $((16#$local_md5)) -ne $((16#$remote_md5)) ]]; then
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}

copy_file(){
    echo $1
    cp -f "$local_channel/$1" "$nginx_channel/$1"
    chmod 755 "$nginx_channel/$1"
}

#combines the above two for one-line use in find command
diff_and_copy(){
    if checksum_diff $1; then
        copy_file $1
    fi
}

main() {
    mkdir -p "$nginx_channel/linux-64"
    mkdir -p "$nginx_channel/noarch"
    cd $local_channel


    echo "checking for diff in linux-64 repodata"
    if checksum_diff "linux-64/repodata.json"; then
        echo "diff found, copying new packages to linux-64"
        for file in linux-64/*; do
            if [[ ! ${file##*/} = "repodata.json" ]]; then
                diff_and_copy "$file"
            fi
        done
        #find linux-64 ! -name "repodata.json" -exec bash -c 'diff_and_copy' bash {} \;
        copy_file "linux-64/repodata.json"
    fi
    echo "checking for diff in noarch repodata"
    if checksum_diff "noarch/repodata.json"; then
        echo "diff found, copying new packages to noarch"
        for file in noarch/*; do
            if [[ ! ${file##*/} = "repodata.json" ]]; then
                diff_and_copy "$file"
            fi
        done
        #find noarch ! -name "repodata.json" -exec bash -c 'diff_and_copy' bash {} \;
        copy_file "noarch/repodata.json"
    fi
}

export -f diff_and_copy
main
