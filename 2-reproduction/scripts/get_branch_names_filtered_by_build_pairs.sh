#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: ./get_branch_names_filtered_by_build_pairs.sh <github repository local path> <build pair list> <output destination>"
    exit -1
fi

REPO=$1
LIST=$2
DEST=$3

if [ ! -d "$REPO" ]; then
    echo "The local github repository must exist ($REPO not found)."
    exit -1
fi

if [ ! -f "$LIST" ]; then
    echo "The file with the list of build pair ids must exist ($LIST not found)."
    exit -1
fi

cd "$REPO"
git pull

git for-each-ref --shell --format="branchname=%(refname:strip=3)" refs/remotes | \
while read entry
do
    eval "$entry"
    if [ "$branchname" == "master" ]; then
        echo "Master branch ignored."
    elif [ "$branchname" == "HEAD" ]; then
        echo "Head ref ignored."
    else
        echo "Treating branch $branchname"
        IFS='-' read -r -a array <<< "$branchname"
        if [ "${#array[@]}" -gt 3 ]; then
            SIZE="${#array[@]}"
            BUGGY_BUILD="${array[ $SIZE -2 ]}"
            FIXER_BUILD="${array[ $SIZE -1 ]}"
            echo "Pair: $BUGGY_BUILD,$FIXER_BUILD"

            if grep -q "$BUGGY_BUILD,$FIXER_BUILD" "$LIST"; then
                IFS='/' read -r -a array2 <<< "$REPO"
                SIZE2="${#array2[@]}"
                REPO_NAME="${array2[ $SIZE2 -1 ]}"
                echo "* https://github.com/fermadeiral/$REPO_NAME/tree/$branchname" >> $DEST
            fi
        fi
    fi
done
