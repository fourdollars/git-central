#!/bin/sh

test_description='server post-receive email notification'

. ./test-lib.sh

export USER_EMAIL=author@example.com

test_expect_success 'setup' '
	echo "setup" >a &&
	git add a &&
	git commit -m "setup" &&
	git clone ./. server &&
	rm -fr server/.git/hooks &&
	git remote add origin ./server &&
	git config branch.master.remote origin &&
	git config branch.master.merge refs/heads/master &&
	GIT_DIR=./server/.git git config hooks.post-receive-email.mailinglist commits@list.com &&
	GIT_DIR=./server/.git git config hooks.post-receive-email.debug true &&
	echo cbas >./server/.git/description
'

install_post_receive_hook 'post-receive-email'

test_expect_success 'simple commit' '
	old_commit_hash=$(git rev-parse HEAD) &&
	old_commit_abbrev=$(git rev-parse --short HEAD) &&

	echo $test_name >a &&
	git commit -a -m "$test_name" &&
	git push &&
	new_commit_hash=$(git rev-parse HEAD) &&
	new_commit_date=$(git log -n 1 --pretty=format:%cd HEAD) &&
	new_commit_abbrev=$(git rev-parse --short HEAD) &&

	interpolate ../t2200-1.txt 1.txt old_commit_hash old_commit_abbrev new_commit_hash new_commit_date new_commit_abbrev &&
	test_cmp 1.txt server/.git/refs.heads.master.out
'

test_expect_success 'simple commit with commitnumber' '
	old_commit_hash=$(git rev-parse HEAD) &&
	old_commit_abbrev=$(git rev-parse --short HEAD) &&

	echo $test_name >a &&
	git commit -a -m "$test_name" &&
	git tag r/1000 &&
	git push --tags &&
	git push &&
	new_commit_hash=$(git rev-parse HEAD) &&
	new_commit_date=$(git log -n 1 --pretty=format:%cd HEAD) &&
	new_commit_abbrev=$(git rev-parse --short HEAD) &&

	interpolate ../t2200-2.txt 2.txt old_commit_hash old_commit_abbrev new_commit_hash new_commit_date new_commit_abbrev &&
	test_cmp 2.txt server/.git/refs.heads.master.out
'

test_done

