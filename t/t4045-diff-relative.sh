#!/bin/sh

test_description='diff --relative tests'
. ./test-lib.sh

test_expect_success 'setup' '
	git commit --allow-empty -m empty &&
	echo content >file1 &&
	mkdir subdir &&
	echo other content >subdir/file2 &&
	git add . &&
	git commit -m one
'

store_diff_relative() {
expect=$1;
cat >expected <<EOF
diff --git a/$expect b/$expect
new file mode 100644
index 0000000..25c05ef
--- /dev/null
+++ b/$expect
@@ -0,0 +1 @@
+other content
EOF
}

store_diff_absolute() {
expect=$1;
cat >expected <<EOF
diff --git a/file1 b/file1
new file mode 100644
index 0000000..d95f3ad
--- /dev/null
+++ b/file1
@@ -0,0 +1 @@
+content
diff --git a/subdir/file2 b/subdir/file2
new file mode 100644
index 0000000..25c05ef
--- /dev/null
+++ b/subdir/file2
@@ -0,0 +1 @@
+other content
EOF
}

check_diff() {
store_diff_relative $1; shift
test_expect_success "-p $*" "
	git diff -p $* HEAD^ >actual &&
	test_cmp expected actual
"
}

check_norel_pre() {
store_diff_relative $1; shift
test_expect_success "-p --no-relative $*" "
	git diff -p --no-relative $* HEAD^ >actual &&
	test_cmp expected actual
"
}

check_norel_post() {
store_diff_absolute $1; shift
test_expect_success "-p $* --no-relative" "
	git diff -p $* --no-relative HEAD^ >actual &&
	test_cmp expected actual
"
}

check_numstat() {
expect=$1; shift
cat >expected <<EOF
1	0	$expect
EOF
test_expect_success "--numstat $*" "
	echo '1	0	$expect' >expected &&
	git diff --numstat $* HEAD^ >actual &&
	test_cmp expected actual
"
}

check_stat() {
expect=$1; shift
cat >expected <<EOF
 $expect | 1 +
 1 file changed, 1 insertion(+)
EOF
test_expect_success "--stat $*" "
	git diff --stat $* HEAD^ >actual &&
	test_i18ncmp expected actual
"
}

check_raw() {
expect=$1; shift
cat >expected <<EOF
:000000 100644 0000000000000000000000000000000000000000 25c05ef3639d2d270e7fe765a67668f098092bc5 A	$expect
EOF
test_expect_success "--raw $*" "
	git diff --no-abbrev --raw $* HEAD^ >actual &&
	test_cmp expected actual
"
}

check_config() {
store_diff_relative $1; shift
test_expect_success "git-config diff.relative=true in $1" "
	(cd $1; git -c diff.relative=true diff -p HEAD^ >../actual) &&
	test_cmp expected actual
"
}

check_config_no_relative() {
store_diff_absolute $1; shift
test_expect_success "--no-relative w/ git-config diff.relative=true in $1" "
	(cd $1; git -c diff.relative=true diff --no-relative -p HEAD^ >../actual) &&
	test_cmp expected actual
"
}

for type in diff numstat stat raw norel_pre norel_post; do
	check_$type file2 --relative=subdir/
	check_$type file2 --relative=subdir
	check_$type dir/file2 --relative=sub
done
for type in config config_no_relative; do
	check_$type file2 subdir/
	check_$type file2 subdir
done

test_done
