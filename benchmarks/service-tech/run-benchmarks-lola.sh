#!/bin/bash

#benchmarks=( 'ibm-soundness' 'sap-reference' )
#benchmarks=( 'sap-reference' )
benchmarks=( 'ibm-soundness' )
extensions=( 'pnet' 'tpn' 'lola' )
executable='/home/philipp/local/lola-2.0/src/lola '

for benchmark in ${benchmarks[@]}; do
  benchmark_dir="$benchmark"
  >$benchmark_dir/positive-lola.list
  >$benchmark_dir/negative-lola.list
  >$benchmark_dir/timeout-lola.list
  >$benchmark_dir/error-lola.list
  for ext in ${extensions[@]}; do
    for file in `find $benchmark_dir -name "*.$ext"`; do
      T="$(date +%s%N)"
      if [ -e $benchmark_dir/final_marking.lola.safe.task ]; then
          final=$benchmark_dir/final_marking.lola.safe.task
      elif [ -e $file.safe.task ]; then
          final=$file.safe.task
      fi
      (
        set -o pipefail;
        $executable -f $file.terminating.task1 $file.terminating --markinglimit=1000000 2>&1 | tee $file.out
      )
      result=$?
      ryes=$(grep "result: yes" $file.out)
      rno=$(grep "result: no" $file.out)
      T=$(($(date +%s%N)-T))
      if [[ -n $ryes ]]; then
          list='positive'
      elif [[ -n $rno ]]; then
          list='negative'
      elif [[ result -eq 2 ]]; then
          list='timeout'
      else
          list='error'
      fi
      echo $T $file >>$benchmark_dir/$list-lola.list
    done
  done
done