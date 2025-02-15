#!/bin/bash
export VERSION="0.1.0"

# Public: builds our current docker image.
#
# Takes the repository, tag, and docker tag that we will use to generate this
# latest image.
#
# $1 - The git repository that we are leveraging
# $2 - The git tag that we are building
# $3 - The docker tag that will be associated with this image
#
build_image() {
    docker build \
        --build-arg GIT_REPO=$1 \
        --build-arg GIT_BRANCH=$2 \
        -t vulcan/ffxi:$3 .
}

# Public: Will provide the commit SHA value for the provided repository and tag.
#
# Will provide back the commit SHA value of the provided git repository and tag
# combo.
#
# $1 - The git repository
# $2 - The git tag that we are interested in
#
# Returns the SHA value of the provided repo:tag combo
#
get_commit_sha() {
    git ls-remote $1 refs/heads/$2 | cut -c1-10
}

GIT_REPO=https://github.com/LandSandBoat/server.git
tags="base"

for tag in $tags; do
    echo Building ${tag}...

    get_commit_sha ${GIT_REPO} ${tag}
    # get the version of our current tag that is building
    version=$(get_commit_sha ${GIT_REPO} ${tag})

    # generate our docker tag (latest)
    docker_tag="${tag}-latest"
    ## build the image
    build_image $GIT_REPO $tag $docker_tag

    # generate our docker tag (version)
    docker_tag="${tag}-${version}"
    ## build the image
    build_image $GIT_REPO $tag $docker_tag
done

# EOF
