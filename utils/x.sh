#!/bin/bash
# An content-based patch generator
#
# What am I born for?
# When you fix some bugs,you always need to upload the only changed files,additional files to the server.
# Find and pick these files by your hands is so sucks that makes you feel bored about work(espeacially when you work with java).
# You can now just focus on fixing bugs,throw dirty work on me.
#
# Usage:
#. Run me with args to init: SCRIPT_NAME init /path/to/your/project
#. After fixing bugs,run me with arg: SCRIPT_NAME gen
#. When "gen patch complete!" appears at console,pick your patch from temp/patch
#. You can check what is in patch by scanning properties file under patch directory
#
#. Empty directory won't be added to patch.
#
# Version 0.1
# Build on: 2014-8-27
# Author: lan

tmp='temp'
target=''

useTime(){
    end=`date +'%s'`
    declare -i use=$(($end-$1))
    echo use $use seconds
}

# Generate md5sum file for init or gen
useMd5(){
    # Ignore vcs files,ide's setting files,and other big&not-frequency-modified files.
    # The bigger size the file is,the more time md5sum costs.
    # This is a whole path match,not search.
    exclude=".*\.(git|idea|setting|svn).*"
    [ $# -eq 2 -a "$2" = "gen" ]&&newer=" -newer $tmp/target"||newer=''
    # Here,compare  mtime at first rather than md5sum. Md5sum is more expensive than newer,don't place it first
    find "$target" $newer -regextype posix-egrep ! -regex "$exclude"  -type f -print0|xargs -0 md5sum >"$tmp"/"$1"
}

# Create a md5sum file for target
init(){
    start=`date +'%s'`
    clean;
    mkdir -p "$tmp"
    # If a path starts with a period '.',we should change it to its absolute path.
    # Because the function 'gen' uses sed,something wrong occurs with '.'.
    target=`dirname "$1"`/`basename "$1"`
    echo "$target">"$tmp"/'target'
    useMd5 former
    echo -en "\ninit complete!\t"
    useTime $start
}

# We use md5sum instead of diff to differ two directories in order to save disk usage and also improve performance
gen(){
    start=`date +'%s'`
    patch=patch
    rm -rf $tmp/$patch
    target=`< "$tmp"/'target'`
    targetParent=`dirname $target`
    simpleTarget=$(basename $target)
    tmpTarget="$tmp"/$simpleTarget
    result=$tmp/"$patch"
    echo
    useMd5 current gen
    diff $tmp/former $tmp/current|egrep '>'|
        awk 'NF==3 {print $3}'|
            sort -u|
                while  read qName
                do
                    [ ! -e "$qName" ]&&continue
                    projectFile=`echo $qName |sed "s,$targetParent,,"`
                    patchFile="$result""$projectFile"
                    parentDir=`dirname $patchFile`
                    if [ -d "$qName" ] ;then
                        mkdir -p $patchFile && cp -r $qName $parentDir
                    else
                        [ ! -e "$parentDir" ]&&mkdir -p "$parentDir"
                        cp "$qName" "$patchFile"
                    fi
                done;
    if [ -e "$result" ]; then
        result="`(cd $result;pwd)`"
        ( cd $result && tar zcf "$simpleTarget"_`date +%Y%m%d-%H%M%S`.tgz "$simpleTarget")
        #Intellj idea start------
        #Generate patch for server,only works for Intellj idea,if you don't use it,delete this code block is okay
        artifact=$result/"$simpleTarget"'/out/artifacts'
        if [ -e "$artifact" ] ; then
            (
            cd $artifact
            mv "$simpleTarget"'_war_exploded' $simpleTarget
            find "$artifact"/"$simpleTarget" -type f|
            sed "s,$artifact/,,g"> "$simpleTarget"_server.properties
            tar zcf "$simpleTarget"_`date +%Y%m%d-%H%M%S`'_server.tgz' "$simpleTarget" "$simpleTarget"_server.properties
            rm "$simpleTarget"_server.properties
            mv *.tgz "$result"/
            )
        fi
        #Intellj idea end------
        echo
        cd "$result";find "$simpleTarget" -type f |tee -a "$simpleTarget".properties|nl
        echo "gen patch complete! "
    else
        echo "no file is updated"
    fi
    useTime $start
}

# Delete the temporary directory
clean(){
    [ -e "$tmp" ]&& rm -rf $tmp
}

# Entry
case $1 in
    'i'|'init')
        [ $# -lt 2 ]&& echo "need one more argument which points to your directory."&& exit;
        shift
        init $1 &;;
    'g'|'gen')
        gen &;;
    'c'|'clean')
        clean &;;
    *)
        echo " usage:"
        echo " `basename $0` init /path/to/your/project"
        echo " `basename $0` gen"
        echo " `basename $0` clean";;
esac
