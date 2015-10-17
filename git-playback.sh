#!/bin/bash

set -e

if [ $# -eq 0 ]; then
  set -- -h
fi

OPTS_SPEC="\
git playback file1 file2 ...

Use left and right arrows to navigate the output.
--
h,help        show the help
s,start=      specify start revision. Default: root commit
e,end=        specify end revision. Default: current branch
n,no-message  don't output commit message
"
eval "$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"

get_git_branch() {
  git branch 2>/dev/null | grep -e ^* | tr -d \*
}

get_root_commit() {
  git rev-list --max-parents=0 HEAD 2>/dev/null | tr -d \*
}

files=()
output_folder='playback'
output_file="$output_folder/error" # should be replaced by hash afterward
output_hash="$output_folder/hash.csv"
output_date="$output_folder/date.csv"
output_change="$output_folder/change.csv"
output_message="$output_folder/message.xml"
start_revision=`get_root_commit`
end_revision=`get_git_branch`
message=true

while [ $# -gt 0 ]; do
  opt="$1"
  shift
  case "$opt" in
    -s) start_revision="$1"; shift;;
    -e) end_revision="$1"; shift;;
    -t) style="$1"; shift;;
    -n) message=false ;;
    *) files+=("$1") ;;
  esac
done




source_file="${BASH_SOURCE[0]}"
while [ -h "$source_file" ]; do
  source_file="$(readlink "$source_file")";
done
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd -P "$(dirname "$source_file")" && pwd)"
unset source_file


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
  for file in ${files[@]}
  do
    if [ -f $file ] && [ -s $file ]; then
      return 0
    else
      return 1
    fi
  done
}

write_file() {
  if [ -f $1 ]; then
    cat $1 >> $output_file
  fi
}

write_diff() {
  if [ -f $1 ]; then
      eval "$(git diff --unified=999999 HEAD~1 $1 | read_diff >> $output_file)"
  fi
}

write_change_count() {
  if [ -f $1 ]; then
      eval "$(git diff --numstat HEAD~1 $1 >> $output_change)"
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
  if $message; then
    eval "$(git log -1 --pretty=format:'<mess>%s</mess>' --abbrev-commit >> $output_message)"
  fi
}

write_start_revision() {
  git checkout --quiet $start_revision

  if has_files; then
    write_hash
    write_commit_message
    write_date
    for file in ${files[@]}
    do
      write_file $file
    done
  fi

  git reset --hard
}

write_revision() {
  if has_files; then
    write_hash
    write_commit_message
    write_date
    for file in ${files[@]}
    do
      write_diff $file
      write_change_count $file
    done
  fi
}

read_diff() {
  OIFS=$IFS
  IFS=''

  read -r s

  while [[ $? -eq 0 ]]
  do
    if [[ $s == diff*  ]] ||
       [[ $s == +++*   ]] ||
       [[ $s == ---*   ]] ||
       [[ $s == @@*    ]] ||
       [[ $s == index* ]]; then
      class='none'
   else
      s=${s# }
      class=
    fi

    if [[ "$class" == 'none' ]]; then
      class='none'
   else
      echo -E $s 
    fi
    read -r s
  done

  IFS=$OIFS
}

#rm -rf $output_folder
mkdir $output_folder
write_start_revision
foreach_git_revision write_revision
