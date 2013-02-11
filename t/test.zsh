#!zsh

. ./test-lib.zsh

. ../zce.zsh

test-zce-genh-loop () {
  T () {
    local b=$1 c=$2 hints=$3 a=$4
    is '[[ $b == _b ]] && [[ $c == _c ]] && [[ $a == _a ]]'
    echo ${(ps.\t.)hints} >tmp
  }
  zce-genh-loop T _a _b _c zce-genh-loop-key "ab" $((0)) 2 '' ' ' 2
  is 'echo b a>tmp2 && cmp tmp tmp2'
  zce-genh-loop T _a _b _c zce-genh-loop-key "ab" $((1+1)) 2 '' ' ' 2
  is 'echo bb ba a>tmp2 && cmp tmp tmp2'
  () {
    setopt localoptions braceccl
    local keys=${(j..)$(print {a-z} {A-Z})}
    zce-genh-loop T _a _b _c zce-genh-loop-key "$keys" $((1+1)) 52 '' ' ' 52
    is 'echo Zb Za Y X W V U T S R Q P O N M L K J I H G F E D C B A \
z y x w v u t s r q p o n m l k j i h g f e d c b a>tmp2 && cmp tmp tmp2'
  }
}

test-zce-1-fail () {
  {
    local failcalledp=nil
    zce-fail () { failcalledp=t }
    K () {}
    zce-1 "a" "BB" K "ab"
    local r=$?
    is '(($r != 0))'
    is '[[ $failcalledp == t ]]'
  } always {
    . ../zce.zsh
  }
  {
    return
    # FIXME
    local failcalledp=nil
    zce-fail () { failcalledp=t }
    K () {}
    #3
    zce-1 "a" $'\e\e'" 1" K "ab"
    is '(($r != 0))'
    is '[[ $failcalledp == t ]]'
  } always {
    . ../zce.zsh
  }
}

test-zce-2-raw () {
  () {
    local tbuffer= tcalledp=
    T () { tbuffer="$3"; tcalledp=t }
    R () { }
    zce-2-raw a aaaaaaaaa \
      $'CC\tCB\tCA\tBC\tBB\tBA\tAC\tAB\tAA' '1 2 3 4 5 6 7 8 9' \
      zce-move-cursor T R
    is '[[ "$tcalledp" == t ]]'
    is '[[ "$tbuffer" == AAABBBCCC ]]'
  }
  {
    local tcursur=0 local tcalledp=nil
    M () { tcursor=$1 }
    T () { tcalledp=t }
    R () { }
    zce-2 () { zce-2-raw "$@" M T R }
    zce-1 "a" " a" zce-2 "ABC"
    is '[[ "$tcalledp" == nil ]]'
    is '(( tcursor == 2 ))'
  } always {
    . ../zce.zsh
  }
}

test-keyin-loop () {
  () {
    R () { : ${(P)1::=B} }
    zce-2-raw a abcabc \
      $'B\tA' '1 4' \
      zce-move-cursor zce-keyin-loop R
    local -i r=$?
    is '(( $r == 0))'
    is '(( $CURSOR == 3))'
  }
  () {
    R () { : ${(P)1::=C} }
    zce-2-raw a abcabc \
      $'B\tA' '1 4' \
      zce-move-cursor zce-keyin-loop R
    local -i r=$?
    is '(( $r == -1))'
  }
}

test-run test-zce-genh-loop test-zce-1-fail test-zce-2-raw test-keyin-loop
