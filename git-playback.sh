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
output_file='playback.html'
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

write_commit_message() {
  if $message; then
    eval "$(git log -1 --pretty=format:'<span>%h</span><span>: </span><span class="keyword">%s</span>' --abbrev-commit >> $output_file)"
  fi
}

write_start_revision() {
  git checkout --quiet $start_revision

  if has_files; then
    write_commit_message
    for file in ${files[@]}
    do
      write_file $file
    done
  fi

  git reset --hard
}

write_revision() {
  if has_files; then
    write_commit_message
    for file in ${files[@]}
    do
      write_diff $file
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

rm -f $output_file
echo "$htmlStart" >> $output_file
write_start_revision
foreach_git_revision write_revision
echo "$htmlEnd" >> $output_file
