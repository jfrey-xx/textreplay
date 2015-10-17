#!/bin/sh

# Convert ANSI (terminal) colours and attributes to HTML

# Licence: LGPLv2
# Author:
#    http://www.pixelbeat.org/docs/terminal_colours/
# Examples:
#    ls -l --color=always | ansi2html.sh > ls.html
#    git show --color | ansi2html.sh > last_change.html
#    Generally one can use the `script` util to capture full terminal output.
# Changes:
#    V0.1, 24 Apr 2008, Initial release
#    V0.2, 01 Jan 2009, Phil Harnish <philharnish@gmail.com>
#                         Support `git diff --color` output by
#                         matching ANSI codes that specify only
#                         bold or background colour.
#                       P@draigBrady.com
#                         Support `ls --color` output by stripping
#                         redundant leading 0s from ANSI codes.
#                         Support `grep --color=always` by stripping
#                         unhandled ANSI codes (specifically ^[[K).
#    V0.3, 20 Mar 2009, http://eexpress.blog.ubuntu.org.cn/
#                         Remove cat -v usage which mangled non ascii input.
#                         Cleanup regular expressions used.
#                         Support other attributes like reverse, ...
#                       P@draigBrady.com
#                         Correctly nest <span> tags (even across lines).
#                         Add a command line option to use a dark background.
#                         Strip more terminal control codes.
#    V0.4, 17 Sep 2009, P@draigBrady.com
#                         Handle codes with combined attributes and color.
#                         Handle isolated <bold> attributes with css.
#                         Strip more terminal control codes.
#    V0.22, 10 Jul 2015
#      http://github.com/pixelb/scripts/commits/master/scripts/ansi2html.sh
#
#    ...and then the butcher came by

gawk --version >/dev/null || exit 1

if [ "$1" = "--version" ]; then
    printf '0.22\n' && exit
fi

if [ "$1" = "--help" ]; then
    printf '%s\n' \
'This utility converts ANSI codes in data passed to stdin
E.g.: ls -l --color=always | ansi2html.sh > ls.html' >&2
    exit
fi


# Mac OSX's GNU sed is installed as gsed
# use e.g. homebrew 'gnu-sed' to get it
if ! sed --version >/dev/null 2>&1; then
  if gsed --version >/dev/null 2>&1; then
    alias sed=gsed
  else
    echo "Error, can't find an acceptable GNU sed." >&2
    exit 1
  fi
fi

printf '%s' "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>
<link rel=\"stylesheet\" type=\"text/css\" href=\"textreplay.css\"/>
</head>

<body class=\"f9 b9\">
<pre>
"

p='\x1b\['        #shortcut to match escape codes

# Handle various xterm control sequences.
# See /usr/share/doc/xterm-*/ctlseqs.txt
sed "
# escape ampersand and quote
s#&#\&amp;#g; s#\"#\&quot;#g;
s#\x1b[^\x1b]*\x1b\\\##g  # strip anything between \e and ST
s#\x1b][0-9]*;[^\a]*\a##g # strip any OSC (xterm title etc.)

s#\r\$## # strip trailing \r

# strip other non SGR escape sequences
s#[\x07]##g
s#\x1b[]>=\][0-9;]*##g
s#\x1bP+.\{5\}##g
# Mark cursor positioning codes \"Jr;c;
s#${p}\([0-9]\{1,2\}\)G#\"J;\1;#g
s#${p}\([0-9]\{1,2\}\);\([0-9]\{1,2\}\)H#\"J\1;\2;#g

# Mark clear as \"Cn where n=1 is screen and n=0 is to end-of-line
s#${p}H#\"C1;#g
s#${p}K#\"C0;#g
# Mark Cursor move columns as \"Mn where n is +ve for right, -ve for left
s#${p}C#\"M1;#g
s#${p}\([0-9]\{1,\}\)C#\"M\1;#g
s#${p}\([0-9]\{1,\}\)D#\"M-\1;#g
s#${p}\([0-9]\{1,\}\)P#\"X\1;#g

s#${p}[0-9;?]*[^0-9;?m]##g

" |

# Normalize the input before transformation
sed "
# escape HTML (ampersand and quote done above)
s#>#\&gt;#g; s#<#\&lt;#g;

# normalize SGR codes a little

# split 256 colors out and mark so that they're not
# recognised by the following 'split combined' line
:e
s#${p}\([0-9;]\{1,\}\);\([34]8;5;[0-9]\{1,3\}\)m#${p}\1m${p}¬\2m#g; t e
s#${p}\([34]8;5;[0-9]\{1,3\}\)m#${p}¬\1m#g;

:c
s#${p}\([0-9]\{1,\}\);\([0-9;]\{1,\}\)m#${p}\1m${p}\2m#g; t c   # split combined
s#${p}0\([0-7]\)#${p}\1#g                                 #strip leading 0
s#${p}1m\(\(${p}[4579]m\)*\)#\1${p}1m#g                   #bold last (with clr)
s#${p}m#${p}0m#g                                          #add leading 0 to norm

# undo any 256 color marking
s#${p}¬\([34]8;5;[0-9]\{1,3\}\)m#${p}\1m#g;

# map 16 color codes to color + bold
s#${p}9\([0-7]\)m#${p}3\1m${p}1m#g;
s#${p}10\([0-7]\)m#${p}4\1m${p}1m#g;

# change 'reset' code to \"R
s#${p}0m#\"R;#g
" |

# Convert SGR sequences to HTML
sed "
# common combinations to minimise html (optional)
:f
s#${p}3[0-7]m${p}3\([0-7]\)m#${p}3\1m#g; t f
:b
s#${p}4[0-7]m${p}4\([0-7]\)m#${p}4\1m#g; t b
s#${p}3\([0-7]\)m${p}4\([0-7]\)m#<span class=\"f\1 b\2\">#g
s#${p}4\([0-7]\)m${p}3\([0-7]\)m#<span class=\"f\2 b\1\">#g

s#${p}1m#<span class=\"bold\">#g
s#${p}4m#<span class=\"underline\">#g
s#${p}5m#<span class=\"blink\">#g
s#${p}7m#<span class=\"reverse\">#g
s#${p}9m#<span class=\"line-through\">#g
s#${p}3\([0-9]\)m#<span class=\"f\1\">#g
s#${p}4\([0-9]\)m#<span class=\"b\1\">#g

s#${p}38;5;\([0-9]\{1,3\}\)m#<span class=\"ef\1\">#g
s#${p}48;5;\([0-9]\{1,3\}\)m#<span class=\"eb\1\">#g

s#${p}[0-9;]*m##g # strip unhandled codes
" |

# Convert alternative character set and handle cursor movement codes
# Note we convert here, as if we do at start we have to worry about avoiding
# conversion of SGR codes etc., whereas doing here we only have to
# avoid conversions of stuff between &...; or <...>
#
# Note we could use sed to do this based around:
#   sed 'y/abcdefghijklmnopqrstuvwxyz{}`~/▒␉␌␍␊°±␤␋┘┐┌└┼⎺⎻─⎼⎽├┤┴┬│≤≥π£◆·/'
# However that would be very awkward as we need to only conv some input.
# The basic scheme that we do in the awk script below is:
#  1. enable transliterate once "T1; is seen
#  2. disable once "T0; is seen (may be on diff line)
#  3. never transliterate between &; or <> chars
#  4. track x,y movements and active display mode at each position
#  5. buffer line/screen and dump when required
sed "
# change 'smacs' and 'rmacs' to a single char so that we can easily do
# negative matching, without using look-behind expressions etc.
s#\x1b(0#\"T1;#g;
s#\x0E#\"T1;#g;

s#\x1b(B#\"T0;#g
s#\x0F#\"T0;#g
" |
(
gawk '
function dump_line(l,del,c,blanks,ret) {
  for(c=1;c<maxX;c++) {
    if ((c SUBSEP l) in attr || length(cur)) {
      ret = ret blanks fixas(cur,attr[c,l])
      if(del) delete attr[c,l]
      blanks=""
    }
    if ((c SUBSEP l) in dump) {
      ret=ret blanks dump[c,l]
      if(del) delete dump[c,l]
      blanks=""
    } else blanks=blanks " "
  }
  if(length(cur)) ret=ret blanks
  return ret
}

function dump_screen(l,ret) {
  for(l=1;l<=maxY;l++)
    ret=ret dump_line(l,0) "\n"
  return ret fixas(cur, "")
}

function atos(a,i,ret) {
  for(i=1;i<=length(a);i++) if(i in a) ret=ret a[i]
  return ret
}

function fixas(a,s,spc,i,attr,rm,ret) {
  spc=length(a)
  l=split(s,attr,">")
  for(i=1;i<=spc;i++) {
    rm=rm?rm:(a[i]!=attr[i]">")
    if(rm) {
      ret=ret "</span>"
      delete a[i];
    }
  }
  for(i=1;i<l;i++) {
    attr[i]=attr[i]">"
    if(a[i]!=attr[i]) {
      a[i]=attr[i]
      ret = ret attr[i]
    }
  }
  return ret
}

function encode(string,start,end,i,ret,pos,sc,buf) {
   if(!end) end=length(string);
   if(!start) start=1;
   state=3
   for(i=1;i<=length(string);i++) {
     c=substr(string,i,1)
     if(state==2) {
       sc=sc c
       if(c==";") {
          c=sc
          state=last_mode
       } else continue
     } else {
       if(c=="\r") { x=1; continue }
       if(c=="<") {
         # Change attributes - store current active
         # attributes in span array
         split(substr(string,i),cord,">");
         i+=length(cord[1])
         span[++spc]=cord[1] ">"
         continue
       }
       else if(c=="&") {
         # All goes to single position till we see a semicolon
         sc=c
         state=2
         continue
       }
       else if(c=="\b") {
          # backspace move insertion point back 1
          if(spc) attr[x,y]=atos(span)
          x=x>1?x-1:1
          continue
       }
       else if(c=="\"") {
          split(substr(string,i+2),cord,";")
          cc=substr(string,i+1,1);
          if(cc=="T") {
              # Transliterate on/off
              if(cord[1]==1&&state==3) last_mode=state=4
              if(cord[1]==0&&state==4) last_mode=state=3
          }
          else if(cc=="C") {
              # Clear
              if(cord[1]+0) {
                # Screen - if Recording dump screen
                if(dumpStatus==dsActive) ret=ret dump_screen()
                dumpStatus=dsActive
                delete dump
                delete attr
                x=y=1
              } else {
                # To end of line
                for(pos=x;pos<maxX;pos++) {
                  dump[pos,y]=" "
                  if (!spc) delete attr[pos,y]
                  else attr[pos,y]=atos(span)
                }
              }
          }
          else if(cc=="J") {
              # Jump to x,y
              i+=length(cord[2])+1
              # If line is higher - dump previous screen
              if(dumpStatus==dsActive&&cord[1]<y) {
                ret=ret dump_screen();
                dumpStatus=dsNew;
              }
              x=cord[2]
              if(length(cord[1]) && y!=cord[1]){
                y=cord[1]
                if(y>maxY) maxY=y
                # Change y - start recording
                dumpStatus=dumpStatus?dumpStatus:dsReset
              }
          }
          else if(cc=="M") {
              # Move left/right on current line
              x+=cord[1]
          }
          else if(cc=="X") {
              # delete on right
              for(pos=x;pos<=maxX;pos++) {
                nx=pos+cord[1]
                if(nx<maxX) {
                  if((nx SUBSEP y) in attr) attr[pos,y] = attr[nx,y]
                  else delete attr[pos,y]
                  if((nx SUBSEP y) in dump) dump[pos,y] = dump[nx,y]
                  else delete dump[pos,y]
                } else if(spc) {
                  attr[pos,y]=atos(span)
                  dump[pos,y]=" "
                }
              }
          }
          else if(cc=="R") {
              # Reset attributes
              while(spc) delete span[spc--]
          }
          i+=length(cord[1])+2
          continue
       }
       else if(state==4&&i>=start&&i<=end&&c in Trans) c=Trans[c]
     }
     if(dumpStatus==dsReset) {
       delete dump
       delete attr
       ret=ret"\n"
       dumpStatus=dsActive
     }
     if(dumpStatus==dsNew) {
       # After moving/clearing we are now ready to write
       # somthing to the screen so start recording now
       ret=ret"\n"
       dumpStatus=dsActive
     }
     if(dumpStatus==dsActive||dumpStatus==dsOff) {
       dump[x,y] = c
       if(!spc) delete attr[x,y]
       else attr[x,y] = atos(span)
       if(++x>maxX) maxX=x;
     }
    }
    # End of line if dumping increment y and set x back to first col
    x=1
    if(!dumpStatus) return ret dump_line(y,1);
    else if(++y>maxY) maxY=y;
    return ret
}
BEGIN{
  OFS=FS
  # dump screen status
  dsOff=0    # Not dumping screen contents just write output direct
  dsNew=1    # Just after move/clear waiting for activity to start recording
  dsReset=2  # Screen cleared build new empty buffer and record
  dsActive=3 # Currently recording
  F="abcdefghijklmnopqrstuvwxyz{}`~"
  T="▒␉␌␍␊°±␤␋┘┐┌└┼⎺⎻─⎼⎽├┤┴┬│≤≥π£◆·"
  maxX=80
  delete cur;
  x=y=1
  for(i=1;i<=length(F);i++)Trans[substr(F,i,1)]=substr(T,i,1);
}

{ $0=encode($0) }
1
END {
  if(dumpStatus) {
    print dump_screen();
  }
}'
)

printf '</pre>
</body>
</html>\n'
