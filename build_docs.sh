#!/bin/bash

set -o errexit -o nounset -o pipefail

rm -rf doc
mkdir doc

bundle exec yard doc

cd doc

git init

git config user.name "Travis CI"
git config user.email "travis@adgear.com"

git add .

git commit -m "Deploy to GitHub Pages"

export github_token="BAD_TOKEN"

exec git push --force --quiet "https://${github_token}@github.com/adgear/html5_zip_file.git" master:gh-pages &>/dev/null
