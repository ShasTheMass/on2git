#!/bin/bash

if [ -z "$1" ]
then
	echo "A folder is needed" 1>&2
	exit 1
fi

# @XXX check that folder exists

# Check that the folder is not on git yet
if [ -d $1/.git ]
then
	echo "The folder is already on Git" 1>&2
	exit 2
fi

cd $1
git init .
REPO=$(basename $1)
git remote add origin https://github.com/$2/${REPO}.git
curl -u "$2" https://api.github.com/user/repos -d "{\"name\":\"$REPO\"}"

FILES=$(find . -not -iwholename '*.git*' -type f)
for f in $FILES
do
	CREATED=$(stat -c '%W' $f)
	MODIFIED=$(stat -c '%Y' $f)
	CHANGED=$(stat -c '%Z' $f)

	echo $f

	if [ $CREATED -ne 0 ]
	then
		VERB='created'
		DATE=$CREATED
	elif [ $MODIFIED -ne 0 ]
	then
		VERB='modified'
		DATE=$MODIFIED
	elif [ $CHANGED -ne 0 ]
	then
		VERB='changed'
		DATE=$CHANGED
	fi

	git add $f > /dev/null && \
		git commit -m "$f $VERB at $DATE" > /dev/null && \
		git filter-branch -f --env-filter "
	export GIT_COMMITTER_DATE='$DATE +0100'
	export GIT_AUTHOR_DATE='$DATE +0100'" HEAD^.. > /dev/null
done

git push -u origin master
