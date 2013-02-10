#!zsh

((succ=0))
((fail=0))
((testn=0))

is () {
  ((testn++))
  {
    if eval "$1"; then
      ((succ++))
      echo ok $testn >>.test-tmp/testn
    else
      echo $1
      echo ${(qqq)functrace}
      ((fail++))
      echo not ok $testn >>.test-tmp/testn
    fi
  } always {
  }
}

test-run () {
  mkdir -p .test-tmp
  {
    : >>.test-tmp/testn
    local f; for f in ${@[@]}; do "$f"; done
    echo 1..$testn
    cat .test-tmp/testn
  } always {
    rm -rf .test-tmp
  }
}
