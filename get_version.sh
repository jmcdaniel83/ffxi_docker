repo=https://github.com/LandSandBoat/server.git
branch=base

# get the latest version number
git ls-remote ${repo} refs/heads/${branch} | cut -c1-10

# EOF

