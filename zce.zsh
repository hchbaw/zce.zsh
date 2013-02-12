# vim's EasyMotion / Emacs's ace-jump-mode for zsh.

# Author: Takeshi Banse <takebi@laafc.net>
# License: BSD-3

# Thank you very much, Kim Silkebækken and winterTTr!
# I want to use the EasyMotion/ace-jump-mode in zsh.

# Code

zce-genh-loop-key () {
  local place="$1"; shift
  local keys="$1"; shift
  local val="${(P)place}"
  local k= l=; for k l in ${@}; do
    local -i i=l; while ((i>0)); do
      val="$val	${${:-${k}${keys[i]}}# }"
      ((i--))
    done
    : ${(P)place::=${val#	}}
  done
}

zce-genh-loop () {
  local   succ="$1"; shift
  local posstr="$1"; shift
  local  qchar="$1"; shift
  local buffer="$1"; shift
  local keyfun="$1"; shift
  local keystr="$1"; shift
  local -i n="$1"; shift
  local -i m="$1"; shift
  local    a="$1"; shift
  local -a as;  :  ${(A)as::=${(s.	.)a}}
  local -a kns; : ${(A)kns::=${(@)@}}

  if ((n == 0)); then
    local tmp=;
    ${keyfun} tmp ${keystr} ${kns[@]}
    ${succ} ${qchar} $buffer ${tmp#	}${a:+"	"}${a} "$posstr"; return $?
  elif [[ -z "$a" ]]; then
    ${keyfun} a ${keystr} ${kns[@]}
    ${0} ${succ} ${posstr} ${qchar} ${buffer} ${keyfun} ${keystr} \
      ${n} ${m} $a; return $?
  else
    local k=${as[1]}; shift as
    local -i len; ((len=n<m?n:m))
    local -i sub=$((len-1)); ((n<=m)) && sub=n
    ${0} ${succ} ${posstr} ${qchar} ${buffer} ${keyfun} ${keystr} \
      $((n - sub)) \
      $m \
      "${(j.	.)as}" \
      "${kns[@]}" \
      "$k" "$((len))"; return $?
  fi
}

zce-1 () {
  setopt localoptions no_ksharrays no_kshzerosubscript extendedglob
  local c="$1"; shift
  local b="$1"; shift
  local kont="$1"; shift
  local keys="$1"; shift
  [[ "$c" == [[:print:]] ]] || return -1
  local -a ps
  local -a match mbegin mend
  local null=$'\0' ok=$'\e\e ' okp=$'\e\e [[:digit:]]##(#e)'

  ps=(${${(M)${(0)${(S)b//*(#b)(${c})/${ok}$mbegin[1]${null}}}:#${~okp}}#${ok}})
  if (($#ps == 0)); then
    zce-fail; return -1
  elif (($#ps > $#keys)); then
    zce-genh-loop "$kont" ${(j. .)ps} $c $b zce-genh-loop-key "$keys" \
      $(($#ps - $#keys + 1)) $#keys '' ' ' $#keys
  else
    zce-genh-loop "$kont" ${(j. .)ps} $c $b zce-genh-loop-key "$keys" \
      0 $#keys '' ' ' $#ps
  fi
}

zce-2 () {
  local c="$1"
  local b="$2"
  local oks="$3"
  local ops="$4"
  zce-2-raw "$c" "$b" "$oks" "$ops" \
    zce-move-cursor zce-keyin-loop zce-keyin-read
}

zce-2-raw () {
  setopt localoptions extendedglob
  local c="$1"; shift
  local b="$1"; shift
  local oks="$1"; local -a ks; : ${(A)ks::=${=1}}; shift
  local ops="$1"; local -a ps; : ${(A)ps::=${(Oa)${=1}}}; shift
  local movecfun="$1"; shift
  local keyinfun="$1"; shift
  local kreadfun="$1"; shift
  local -i i; ((i=$#ps))

  if (($i==0)); then
    zce-fail; return $?
  elif (($i==1)); then
    $movecfun $ps[1]; return $?
  fi

  local -i n=1
  local null=$'\0'
  local MATCH MBEGIN MEND
  ${keyinfun} '' "$b" "${b//(#m)${c}/${ks[i--][1]}}" \
    "${movecfun}" "${keyinfun}" "${kreadfun}" \
    -- ${(s. .)${:-"${oks//(#m)$'\t'/$null$ps[((n++))] }$null$ps[n]"}}
}

zce-fail () {
  return -1
}

zce-move-cursor () {
  ((CURSOR = $1 - 1))
  return 0
}

zce-readc () {
  echoti sc
  echoti cud 1
  echoti hpa 0
  echoti el
  print -Pn $2
  read -s -k 1 $1
  local ret=$?
  echoti hpa 0
  echoti el
  echoti rc
  return $ret
}

zce-keyin-read () {
  local s=; zstyle -s ':zce:*' prompt-key s || \
    s='%{\e[1;32m%}Target key:%{\e[0m%} '
  zce-readc "$1" "$s"
}

zce-keyin-loop () {
  local -a region_highlight
  local fg=; zstyle -s ':zce:*' fg fg || fg='fg=196,bold'
  local bg=; zstyle -s ':zce:*' bg bg || bg='fg=black,bold'
  zce-keyin-loop-raw "$fg" "$bg" "$@"
}

zce-keyin-loop-raw () {
  setopt localoptions extendedglob
  local hispec="$1"; shift
  local dimspec="$1"; shift
  local key="$1"; shift
  local ob="$1"; shift
  local nb="$1"; shift
  local movecfun="$1"; shift
  local keyinfun="$1"; shift
  local kreadfun="$1"; shift
  shift; # dashdash

  local -i c=0; ((c=$#@))
  if ((c == 0)); then
    zce-fail; return -1
  elif ((c == 1)); then
    zce-move-cursor ${1#*$'\0'}; return 0
  fi

  local MATCH MBEGIN MEND
  if [[ -z "$key" ]]; then
    BUFFER="$nb"
    region_highlight=("0 $#BUFFER $dimspec")
    region_highlight+=(${${@#*$'\0'}/(#m)[[:digit:]]##/$((MATCH-1)) $MATCH $hispec})
  else
    nb="$ob"
    local tmp; for tmp in ${(M)@:#${key}*}; do
      nb[${tmp#*$'\0'}]="${${tmp%$'\0'*}[(($#key+1))]}"
    done
    BUFFER="$nb"
    region_highlight=("0 $#BUFFER $dimspec")
    region_highlight+=(${${${(M)@:#${key}*}#*$'\0'}/(#m)[[:digit:]]##/$((MATCH-1)) $MATCH $hispec})
  fi
  zle -R

  local key2=; ${kreadfun} key2 && \
    ${0} $hispec $dimspec "${key}${key2}" "$ob" "$nb" \
      "$movecfun" "$keyinfun" "$kreadfun" \
      --  "${(M)@:#${key}${key2}*}" || {
    zce-fail; return -1
  }
}

with-zce () {
  zmodload zsh/terminfo 2>/dev/null
  setopt localoptions extendedglob braceccl
  local orig_buffer="$BUFFER"
  local -i orig_cursor; ((orig_cursor=CURSOR))
  ((CURSOR=$#BUFFER)); zle -R
  local -a region_highlight
  {
    local keys=; zstyle -s ':zce:*' keys keys || \
      keys=${(j..)$(print {a-z} {A-Z})}
    "$@" "$keys" || { ((CURSOR=orig_cursor)) }
  } always {
    BUFFER="$orig_buffer"
    zle redisplay
  }
}

zce-searchin-read () {
  local s=; zstyle -s ':zce:*' prompt-char s || \
    s='%{\e[1;32m%}Search for character:%{\e[0m%} '
  zce-readc "$1" "$s"
}

zce-raw () {
  local c=; "$1" c
  [[ "$c" == [[:print:]] ]] && {
    zce-1 "$c" "$BUFFER" zce-2 "$2"
  }
}

zce () { with-zce zce-raw zce-searchin-read }

zle -N zce
