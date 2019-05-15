# Tag the repo with a new release version
#
# USAGE:
#
#   make release VERSION=8.8 MESSAGE="This version does something awesome"
#
# This will push your tag and message, and create a new branch containing
# a commit to update the version badge in the README.
#
# You then need to raise a PR to get the badge change approved and merged.
#
release:
	# Tags are top-level entities in git, so it doesn't matter
	# in which order we tag and branch the repo.
	git tag $${VERSION} -m "$${MESSAGE}"
	git checkout -b update-version-to-$${VERSION}
	make update-badge
	git add README.md
	git commit -m "Update version badge in README.md to $${VERSION}"
	git push --follow-tags origin update-version-to-$${VERSION}
	echo "\n\nRelease $${VERSION} created. Please raise a PR from this branch\n"

# Update the README.md version badge with the last tag (alphabetically)
update-badge:
	version=$$(git tag --list | tail -1); \
		sed -i '' "s/badge.version-[0-9]*\.[0-9]*-green.svg/badge\/version-$${version}-green.svg/" README.md

.PHONY: release update-badge

