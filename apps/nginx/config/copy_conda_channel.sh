#!/usr/bin/env sh

share="/nginx-share"
nginx_channel="$share/nginx/html/condapkg"
local_channel="/home/jovyan/local-channel"


checksum_diff(){
    if [[ -f "$nginx_channel/$1" ]]; then

        local_md5=($(md5sum "$local_channel/$1"))
        remote_md5=($(md5sum "$nginx_channel/$1"))

        if [[ $local_md5 -ne $remote_md5 ]]; then
            printf "found diff at $1\n"
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}

copy_file(){
    cp -af "$local_channel/$1" "$nginx_channel/$1"
}

#combines the above two for one-line use in find command
diff_and_copy(){
    if [[ checksum_diff $1 ]]; then
        copy_file $1
    fi
}

main() {
    mkdir -p "$nginx_channel"
    mkdir -p "$nginx_channel/linux-64"
    mkdir -p "$nginx_channel/noarch"
    pushd /home/joyvan/local-channel


    printf "checking for diff in linux-64 repodata\n"
    if [[ checksum_diff "linux-64/repodata.json" ]]; then
        printf "copying new packages"
        find linux-64 ! -name "repodata.json" -exec diff_and_copy {} \;
        copy_file "linux-64/repodata.json"
    fi
    printf "copying noarch packages to nginx fileserver"
    if [[ checksum_diff "noarch/repodata.json" ]]; then
        printf "copying new packages"
        find noarch ! -name "repodata.json" -exec diff_and_copy {} \;
        copy_file "noarch/repodata.json"
    fi


}

main
