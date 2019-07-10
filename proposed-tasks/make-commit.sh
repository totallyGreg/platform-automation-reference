#!/bin/bash

cat /var/version && echo ""
set -eu
git config --global user.email "$GIT_AUTHOR_EMAIL"
git config --global user.name "$GIT_AUTHOR_NAME"

git clone repository repository-commit

mkdir -p $(dirname repository-commit/"$FILE_DESTINATION_PATH")

cp file-source/"$FILE_SOURCE_PATH" \
   repository-commit/"$FILE_DESTINATION_PATH"
cd repository-commit
if [[ -n $(git status --porcelain) ]]; then
  git add -A
  git commit -m "$COMMIT_MESSAGE" --allow-empty
fi
