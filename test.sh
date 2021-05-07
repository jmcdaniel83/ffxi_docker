GIT_REPO=https://github.com/project-topaz/topaz.git

tags="release canary trust"

for i in $tags; do
#	git ls-remote ${GIT_REPO} refs/heads/${i}
	version=$(git ls-remote ${GIT_REPO} refs/heads/${i} | cut -c1-10) 
	echo $i: $version
done
