#!/bin/bash
# set -x
parts=$1

if [ "$parts" == "" ]; then
    parts="1 2 3";
fi


scriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# echo "$scriptdir"

file=$2
echo $file
function myecho {
    if [ $2 -ne 0 ]; then
        if ! [ -z $file ]; then
            echo "$1" >> $scriptdir/$file
        else
            echo "$1"
        fi
    fi
}

function grade_bin {
    LB=$2
    HB=$3
    BINS=$4
    UNIT=$5
    d=$6
    local score=0
    for ((number=BINS; number>0; number--)); do
        if [ $BINS -eq 1 ]; then
            range=$HB
        else
	        range=$(echo "$LB+($HB-$LB)/($BINS-1)*($number-1)" | bc)
        fi
        re='^[0-9]+$'
        if  [[ $d =~ $re ]] ; then
	        cond=$(echo "$d <= $range" | bc 2>/dev/null)
	        if [ $cond -eq 1 ]; then
			    myecho "Project.$1_LE_$range: PASSED" 1
                score=$(($score+1))
		    else 
			    myecho "Project.$1_LE_$range: FAILED, you have $d $UNIT which is greater than $range $UNIT" 1
		    fi
	    else 
		    myecho "Project.$1_LE_$range: $d" 1
		fi
	done;
    return $score;
}

# 1: test name
# 2: test command
# 3: previous test status, 0 success 1 fail
# 4: previous test name
# 5: do echo or not (!0, 0)
function run_or_timeout {
  if [ $3 -ne 0 ] ; then
      myecho "Project.$1: FAILED You must pass the $4 before running other tests" $5
      failmsg="FAILED You must pass the $4 before running other tests"
      return 1
  fi
  result="$(timeout 400s $2)"
  if [ $? -eq 124 ] ; then
      myecho "Project.$1: FAILED TEST TIMEOUT" $5
      failmsg="FAILED TEST TIMEOUT"
    return 1
  fi
  failed=$(echo "$result" | grep "FAILED")
  passed=$(echo "$result" | grep "PASSED")
  if [ -n "$failed" ] || [ -z "$passed" ] ; then
      myecho "Project.$1: FAILED" $5
      failmsg="FAILED"
      return 1
  fi
  myecho "Project.$1: PASSED" $5
  return 0
}

score_sec1=0
score_sec2=0
score_sec3=0

for part in $parts
do
    cd $scriptdir
    if [ $part == "1" ]; then
        cd sw/sort_opt
        make all -j
        if [ -f ./sort.vmh ]; then
            out_test=`python sim.py --auto`
            pass=`echo "$out_test" | grep -Eo "PASSED"`
            fail=`echo "$out_test" | grep -Eo "FAILED"`
            if [ -n "$fail" ]; then
                myecho "Project.Section_1_sort_test: FAILED" 1
                instrs="FAILED, sort_test failed"
            elif ! [[ -z "$pass" ]] ; then
                myecho "Project.Section_1_sort_test: PASSED" 1
		instrs=`echo "$out_test" | grep -E "Executed Instrs " | sed  's/||.*//g' | grep -Eo "([0-9]+)"`
            else
                myecho "Project.Section_1_sort_test: FAILED, neither passed nor failed printed" 1
                instrs="FAILED, neither passed nor failed printed"
            fi
        else
            myecho "Project.sort_test: FAILED, compilation error" 1
            instrs="FAILED, compilation error"
        fi

        grade_bin "Section_1_sort_sw_optimization" 350000 400000 2 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        grade_bin "Section_1_sort_sw_optimization" 240000 300000 2 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        grade_bin "Section_1_sort_sw_optimization" 180000 180000 1 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        echo "Section 1 Score = $score_sec1"
    elif [ $part == "2" ]; then
        # Part 2: ProcessorIPC
        run_or_timeout "Section_2_ProcessorIPC-fullasmtests" "./test.sh -s -p 1 -t 6" 0 none 1
        run_or_timeout "Section_2_ProcessorIPC-sort_gcc_baseline" "./test.sh -s -p 1 -t 13" $? fullasmtests 0
        succeed=$?
        cycles=$failmsg
        if [ $succeed -eq 0 ]; then
            periodlimit=550
            period=`echo "$result" | grep -Eo "has clock period of = ([0-9]+\.?[0-9]*) ps" | grep -Eo "([0-9]+\.?[0-9]*)"`
            cond=`echo "$period <= $periodlimit" | bc 2> /dev/null`
            if [ $cond -eq 1 ]; then
                cycles=`echo "$result" | grep -Eo "Total Cycles = ([0-9]+)" | grep -Eo "([0-9]+)"`

            else
                cycles="FAILED, Your processor has clock period ($period ps) exceeding $periodlimit ps"
            fi
        fi
        grade_bin "Section_2_ProcessorIPC-sort_gcc_baseline" 500000 720000 10 cycles "$cycles"
        score_sec2=$(($score_sec2+$?))
        echo "Section 2 Score = $score_sec2"
    elif [ $part == "3" ]; then
        # Part 3: ProcessorRuntime

        run_or_timeout "Section_3_ProcessorRuntime-fullasmtests" "./test.sh -s -p 2 -t 6" 0 none 1
        run_or_timeout "Section_3_ProcessorRuntime-sort_test" "./test.sh -s -q -p 2 -t 12" $? fullasmtests 1
        run_or_timeout "Section_3_ProcessorRuntime-sort_benchmark" "./test.sh -s -p 2 -t 14" $? fullasmtest 0
        succeed=$?
        runtime="$failmsg"
        if [ $succeed -eq 0 ]; then
            runtime=`echo "$result" | grep -Eo "Runtime = ([0-9]+)" | grep -Eo "([0-9]+)"`
        fi
        grade_bin "Section_3_ProcessorRuntime-sort_benchmark" 120000 180000 5 ns "$runtime"
        score_sec3=$(($score_sec3+$?))
        echo "Section 3 Score = $score_sec3"
    fi
done


# exit success here otherwise makefile will complain
exit 0;
