#!/bin/bash

set -e

if [ $# -eq 0 ]; then
  set -- -h
fi

OPTS_SPEC="\
git playback file ...

--
h,help        show the help
s,start=      specify start revision. Default: root commit
e,end=        specify end revision. Default: current branch
"
eval "$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"

get_git_branch() {
  git branch 2>/dev/null | grep -e ^* | tr -d \*
}

get_root_commit() {
  git rev-list --max-parents=0 HEAD 2>/dev/null | tr -d \*
}

file=()
output_folder='textreplay_playback_output'
output_file="$output_folder/error" # should be replaced by hash afterward
output_hash="$output_folder/hash.csv"
output_date="$output_folder/date.csv"
output_change="$output_folder/change.csv"
output_message="$output_folder/message.xml"
start_revision=`get_root_commit`
end_revision=`get_git_branch`
total_commits=0

while [ $# -gt 0 ]; do
  opt="$1"
  shift
  case "$opt" in
    -s) start_revision="$1"; shift;;
    -e) end_revision="$1"; shift;;
    *) file+=("$1") ;;
  esac
done

source_file="${BASH_SOURCE[0]}"
while [ -h "$source_file" ]; do
  source_file="$(readlink "$source_file")";
done
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd -P "$(dirname "$source_file")" && pwd)"
unset source_file

css_file="${script_dir}/textreplay.css"

fetch_number_commits() {
  echo `git rev-list HEAD --count`
}

foreach_git_revision() {
  command=$1

  revisions=`git rev-list --reverse ${end_revision} ^${start_revision}`

  for revision in $revisions; do
      git checkout --quiet $revision
      eval $command
      git reset --hard
  done

  git checkout --quiet $end_revision
}

has_files() {
 if [ -f $file ] && [ -s $file ]; then
    return 0
  else
    return 1
  fi
}

has_diff() {
  git diff HEAD HEAD~1 --exit-code $1 > /dev/null
  return $(($?==0))
}

write_file() {
  if [ -f $1 ]; then
    cat $1 >> $output_file
  fi
}

get_added_chars() {
  if [ -f $1 ]; then
    # got idea from http://stackoverflow.tcom/a/28183710
    local nbChars=$(git diff --word-diff=porcelain HEAD~1 $1 | grep -e '^+[^+]' | wc -m)
    # inflation cause of "+" and line ternimation, we wille remove that
    local nbLines=$(git diff --word-diff=porcelain HEAD~1 $1 | grep -e '^+[^+]' | wc -l)
    echo $((nbChars-2*nbLines))
  fi
}

get_deleted_chars() {
  if [ -f $1 ]; then
    local nbChars=$(git diff --word-diff=porcelain HEAD~1 $1 | grep -e '^-[^-]' | wc -m)
    local nbLines=$(git diff --word-diff=porcelain HEAD~1 $1 | grep -e '^-[^-]' | wc -l)
    echo $((nbChars-2*nbLines))
  fi
}

write_diff() {
  if [ -f $1 ]; then
       git diff 
      # remove first 4 lines, git diff header
      eval "$(git diff --color-words --patience --unified=999999 HEAD~1 $1 | tail -n +6 > $output_file)"
 fi
}

write_change_count() {
  if [ -f $1 ]; then
      echo "$(get_added_chars $1) $(get_deleted_chars $1)" >> $output_change
  fi
}

write_change_count_start() {
  # on init, just output file size
  if [ -f $1 ]; then
      echo "$(wc -m < $1) 0" >> $output_change
  fi
}

write_date() {
  # get author date of current commit
  if [ -f $1 ]; then
      eval "$(git show -s --format='%ai' >> $output_date)"
  fi
}

write_hash() {
    # update also output filename
    cur_hash=`eval "git log --pretty=format:'%Hh' -n 1"`
    output_file=$output_folder/$cur_hash
    echo $cur_hash >> $output_hash
}

write_commit_message() {
    eval "$(git log -1 --pretty=format:'<mess>%s</mess>' --abbrev-commit >> $output_message && echo "" >> $output_message)"
}

write_start_revision() {
  echo "Total number of commits: $total_commits"
  git checkout --quiet $start_revision
  if has_files; then
    pre_hook $output_file
    write_hash
    write_commit_message
    write_date
    write_file $file
    write_change_count_start $file
    post_hook $output_file
  else
      echo "No file at start"
  fi
  git reset --hard
}

write_revision() {
   if has_files; then
     if has_diff $file; then
       pre_hook $output_file
       write_hash
       write_commit_message
       write_date
       write_diff $file
       write_change_count $file
       post_hook $output_file
     else
	 echo "No change"
     fi
  else
       echo "No file at diff"
  fi
}

pre_hook() {
  echo "commit `fetch_number_commits` / $total_commits"
}

post_hook() {
  if [ -f $1 ]; then
    # doingthe hard stuff
    echo "converting $1 to html..."
    cat $1 | sh ${script_dir}/ansi2html.sh > $1.html 
  fi
}

total_commits=`fetch_number_commits`

rm -rf $output_folder
mkdir $output_folder
cp ${css_file} ${output_folder}
write_start_revision
foreach_git_revision write_revision
