#!/bin/bash

# This script automates the gem release project for this repo.

GEM_NAME=arduino_ci
GEM_MODULE=ArduinoCI
PUSH_REMOTE=upstream

# test if we have an arguments on the command line
if [ $# -lt 1 ]
then
    echo "You must pass an argument for KeepAChangelogManager:"
    bundle exec keepachangelog_manager.rb
    exit 1
fi

# set up a cleanup function for any errors, so that we git stash pop
cleanup () {
  set +x +e
  echo -e "\n### Reverting uncommitted changes"
  git checkout README.md CHANGELOG.md lib/$GEM_NAME/version.rb
  if [ $DID_STASH -eq 0 ]; then
    echo -e "\n### Unstashing changes"
    git stash pop
  fi
  exit $1
}

DIDNT_STASH="No local changes to save"
DID_STASH=1
echo -ne "\n### Stashing changes..."
STASH_OUTPUT=$(git stash save)
[ "$DIDNT_STASH" != "$STASH_OUTPUT" ]
DID_STASH=$?
echo DID_STASH=$DID_STASH

trap "cleanup 1" INT TERM ERR
set -xe

echo "### Checking existence of specified git push destination '$PUSH_REMOTE'"
git remote get-url $PUSH_REMOTE

# ensure latest master
git pull --rebase

# update version in changelog and save it
NEW_VERSION=$(bundle exec keepachangelog_manager.rb $@)

echo "Checking whether new version string is a semver"
echo $NEW_VERSION | grep -Eq ^[0-9]*\.[0-9]*\.[0-9]*$

# write version.rb with new version
cat << EOF > lib/$GEM_NAME/version.rb
module $GEM_MODULE
  VERSION = "$NEW_VERSION".freeze
end
EOF

# update README with new version
sed -e "s/\/gems\/$GEM_NAME\/[0-9]*\.[0-9]*\.[0-9]*)/\/gems\/$GEM_NAME\/$NEW_VERSION)/" -i "" README.md

# mutation!
git add README.md CHANGELOG.md lib/$GEM_NAME/version.rb
git commit -m "v$NEW_VERSION bump"
git tag -a v$NEW_VERSION -m "Released version $NEW_VERSION"
gem build $GEM_NAME.gemspec
gem push $GEM_NAME-$NEW_VERSION.gem
git push $PUSH_REMOTE
git push $PUSH_REMOTE --tags
git fetch

# do normal cleanup
cleanup 0
