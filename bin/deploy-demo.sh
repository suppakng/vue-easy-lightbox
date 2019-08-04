#!/usr/bin/env sh

# abort on errors
set -e

# remove babel cache
rm -r ./node_modules/.cache/babel-loader/


# build
npm run build:demo

# navigate into the build output directory
cd build

git init
git add -A
git commit -m 'update'
git push -f git@github.com:XiongAmao/vue-easy-lightbox.git master:gh-pages

cd -

echo DONE!
