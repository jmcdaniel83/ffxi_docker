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
        --build-arg GIT_VERSION=$2 \
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



#GIT_REPO=https://github.com/project-topaz/topaz.git
#tags="release canary trust"
GIT_REPO=https://github.com/topaz-next/topaz.git
tags="release canary"

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



# GIT_REPO=https://github.com/zach2good/topaz.git
# tags='trust_full_gambit'
# tag-version=get_commit_sha ${GIT_REPO} ${tags}
# build_image ${GIT_REPO} ${tags}

# trust_version=`git ls-remote ${GIT_REPO} refs/heads/${GIT_VERSION} | cut -c1-10`

# docker build \
#     --build-arg GIT_VERSION=trust \
#     -t vulcan/ffxi:trust-latest .
# #docker build --build-arg GIT_VERSION=trust  -t vulcan/ffxi:trust-2d27a3ee7a .
# #1edc824b9d

# docker build \
#     --build-arg GIT_VERSION=canary \
#     -t vulcan/ffxi:canary-latest .

# docker build \
#     --build-arg GIT_VERSION=release \
#     -t vulcan/ffxi:release-latest .

# # test gambits
# docker build \
#     --build-arg GIT_REPO=https://github.com/zach2good/topaz.git \
#     --build-arg GIT_VERSION=trust_full_gambit \
#     -t vulcan/ffxi:trust-testing-latest .

# #docker build -t vulcan/ffxi:canary-latest --build-arg GIT_VERSION=canary .
# #docker build -t vulcan/ffxi:canary-5d29f15540 --build-arg GIT_VERSION=canary .

# #docker build -t vulcan/ffxi:release-latest --build-arg GIT_VERSION=release .
# #docker build -t vulcan/ffxi:release-bdf076b9c6 --build-arg GIT_VERSION=release .

# EOF

