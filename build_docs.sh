#!/bin/bash

rm -rf doc || exit 0;
mkdir doc

bundle exec yard doc

cd doc

git init

git config user.name "Travis CI"
git config user.email "travis@adgear.com"

git add .

git commit -m "Deploy to GitHub Pages"

git push --force --quiet "https://${github_token}@github.com/adgear/html5_zip_file.git" master:gh-pages #> /dev/null 2>&1

echo "git push exit code: ${?}"
