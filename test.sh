#!/bin/bash
cd sw
make
cd ..



VERBOSE=1
SYNTH=1

printUsage() {
    echo "Usage: ./test.sh [-s|--summary] [-q|--quick] [-p|--proc PROCESSOR_ID] [-t|--test TESTSET_ID]"
    echo "PROCESSOR_ID:"
    echo "  1) ProcessorIPC"
    echo "  2) ProcessorRuntime"
    echo "  3) all"
    echo "TESTSET_ID:"
    echo "  1) microtest 1_lui"
    echo "  2) microtest 2_addi"
    echo "  3) microtest 3_add"
    echo "  4) microtest 4_bne"
    echo "  5) all microtests"
    echo "  6) full asm tests"
    echo "  7) pipetest 1_no_hazards"
    echo "  8) pipetest 2_all_data_hazards"
    echo "  9) pipetest 3_all_control_hazards"
    echo "  10) pipetest 4_all_hazards"
    echo "  11) all pipetests"
    echo "  12) sort_test"
    echo "  13) sort_gcc_baseline"
    echo "  14) sort_benchmark"
}


while [[ $# -gt 0 ]];
do
    key="$1"
    case $key in
        -s|--summary)
            VERBOSE=0
            shift # past argument
            ;;
        -q|--quick)
            SYNTH=0
            shift # past argument
            ;;
        -p|--proc)
            procResponse="$2"
            shift
            shift
            ;;
        -t|--test)
            testResponse="$2"
            shift # past argument
            shift # past argument
            ;;
        -h|--help)
            printUsage;
            exit;
            ;;
        *)
            printUsage;
            exit;
            ;;
    esac
done

microtests="1_lui.vmh 2_addi.vmh 3_add.vmh 4_bne.vmh"

# if [ "$#" -gt 0 ] ; then
#     response=$1
# else
if [ -z $procResponse ]; then
    echo "What processor do you want to test?"
    echo "1) ProcessorIPC"
    echo "2) ProcessorRuntime"
    echo "3) all"
    read procResponse
fi

case $procResponse in
    1)  processors=ProcessorIPC ;;
    2)  processors=ProcessorRuntime ;;
    3)  processors="ProcessorIPC ProcessorRuntime" ;;
    *)  echo "ERROR: Unexpected response: $response" ; exit ;;
esac

# if [ "$#" -gt 1 ] ; then
#     response=$2
# else
if [ -z $testResponse ]; then
    echo "What would you program would you like to run?"
    echo "1) microtest 1_lui"
    echo "2) microtest 2_addi"
    echo "3) microtest 3_add"
    echo "4) microtest 4_bne"
    echo "5) all microtests"
    echo "6) full asm tests"
    echo "7) pipetest 1_no_hazards"
    echo "8) pipetest 2_all_data_hazards"
    echo "9) pipetest 3_all_control_hazards"
    echo "10) pipetest 4_all_hazards"
    echo "11) all pipetests"
    echo "12) sort_test"
    echo "13) sort_gcc_baseline"
    echo "14) sort_benchmark"
    read testResponse
fi

case $testResponse in
    1)  microtests=01_lui; folders=microtests ;;
    2)  microtests=02_addi;  folders=microtests ;;
    3)  microtests=03_add;  folders=microtests ;;
    4)  microtests=04_bne;  folders=microtests ;;
    5)  microtests=`ls sw/build/microtests/*.vmh`; folders=microtests ;;
    6)  folders="fullasmtests";;
    7)  microtests=01_no_hazards; folders=pipetests ;;
    8)  microtests=02_all_data_hazards;  folders=pipetests ;;
    9)  microtests=03_all_control_hazards;  folders=pipetests ;;
    10)  microtests=04_all_hazards;  folders=pipetests ;;
    11)  microtests=`ls sw/build/pipetests/*.vmh`; folders="pipetests";;
    12)  microtests=sort_test; folders="sort";;
    13)  microtests=sort_base; folders="sort";;
    14)  microtests=sort_bench; folders="sort";;
    15)  folders="gcdtests";;
    *)  echo "ERROR: Unexpected response: $response" ; exit ;;
esac


for processor in $processors
do
    echo $folders
    if [ "$folders" == "microtests" ] || [ "$folders" == "pipetests" ] ; then
       for microtest in $microtests
       do
           microtest=$(basename "$microtest")
           microtest="${microtest%.*}"
           mkdir -p test_out/$folders/$processor
           echo "Running $folder $microtest on $processor"
           rm -f mem.vmh
           ln -s sw/build/$folders/$microtest.vmh mem.vmh
           if [ $VERBOSE -eq 1 ]; then
               ./$processor 2>&1 | tee test_out/$folders/$microtest.out
           else
               ./$processor &> test_out/$folders/$microtest.out
           fi
           out=`cat test_out/$folders/$microtest.out`
           
           procStat=`cat test_out/$folders/$microtest.out | sed -n '/Dumping the state/,$p'`
           fname=expected/$folders/$microtest.expected
           expected_procStat=`cat $fname | sed -n '/Dumping the state/,$p'`
           if [ "$procStat" = "$expected_procStat" ]; then
               echo "PASSED"
           else
               echo "FAILED"
           fi
       done
    elif [ "$folders" == "sort" ] ; then
        mkdir -p test_out/$folders
       for microtest in $microtests
       do
           if [ "$microtest" != sort_bench ]; then
              rm -f mem.vmh
              ln -s sw/build/sort/$microtest.vmh mem.vmh
              echo "Running sort $microtest on $processor"


              if [ $VERBOSE -eq 1 ]; then
                  ./$processor 2>&1 | tee test_out/$folders/$microtest.out
              else
                  ./$processor &> test_out/$folders/$microtest.out
                  cat test_out/$folders/$microtest.out | sed -e 's/.*Dumping the.*/FAILED/' | grep -E ".*PASSED.*|.*FAILED.*"
              fi

              
              out=`cat test_out/$folders/$microtest.out`
              cycle=`echo "$out" | grep -E "Total Clock Cycles = " | tail -1 | grep -Eo "([0-9]+)"`
              #insts=`echo "$out" | grep -E "Total Instruction Count =" | grep -Eo "([0-9]+)"`
              #ipc=`echo "scale=4; $insts/$cycle" | bc`
              #echo "Total Cycles = $cycle, Instruction Count = $insts, IPC = $ipc"
              echo "Total Cycles = $cycle"

              echo "$processor, $cycle" >> base.csv
               if [ $SYNTH -eq 1 ]; then
                  echo "Running synth ..."
                  synthout=`synth $processor.bsv mkProcessor -l multisize`
		  failed=$(echo "$synthout" | grep "Error")
		  passed=$(echo "$synthout" | grep "Synthesis complete")
		  if [ -n "$failed" ] || [ -z "$passed" ] ; then
		      echo "FAILED -- Synthesis did not complete successfully" 
		  else
                      period=`echo "$synthout" | grep -E "Critical-path delay:" | grep -Eo "([0-9]+\.?[0-9]*)"`
                      area=`echo "$synthout" | awk '/^Area breakdown/{p=1;print;next} p&&/^Memories used:/{p=0};p' | grep -E "Total" | grep -Eo "([0-9]+\.[0-9]+)"`
                      echo "$processor has clock period of = $period ps, area (excluding memory) = $area um^2"
                      runtime=`echo "$period*$cycle/1000" | bc`
                      echo "Runtime = $runtime ns ($period ps * $cycle)"
		  fi
               fi
              
           else

               microtest="sort_bench"
               echo "Running sort $microtest on $processor"
               rm -f mem.vmh
               ln -s sw/build/sort/$microtest.vmh mem.vmh

               if [ $VERBOSE -eq 1 ]; then
                   ./$processor 2>&1 | tee test_out/$folder/$microtest.out
               else
                   ./$processor &> test_out/$folder/$microtest.out
                   cat test_out/$folder/$microtest.out | sed -e 's/.*Dumping the.*/FAILED/' | grep -E ".*PASSED.*|.*FAILED.*"
               fi

               out=`cat test_out/$folder/$microtest.out`
               cycle=`echo "$out" | grep -E "Total Clock Cycles = " | tail -1 | grep -Eo "([0-9]+)"`
               #insts=`echo "$out" | grep -E "Total Instruction Count =" | grep -Eo "([0-9]+)"`
               #ipc=`echo "scale=4; $insts/$cycle" | bc`
               #echo "Total Cycles = $cycle, Instruction Count = $insts, IPC = $ipc"
               echo "Total Cycles = $cycle"
                              

               if [ $SYNTH -eq 1 ]; then
                  echo "Running synth ..."
                  synthout=`synth $processor.bsv mkProcessor -l multisize`
		  failed=$(echo "$synthout" | grep "Error")
		  passed=$(echo "$synthout" | grep "Synthesis complete")
		  if [ -n "$failed" ] || [ -z "$passed" ] ; then
		      echo "FAILED -- Synthesis did not complete successfully" 
		  else
                      period=`echo "$synthout" | grep -E "Critical-path delay:" | grep -Eo "([0-9]+\.?[0-9]*)"`
                      area=`echo "$synthout" | awk '/^Area breakdown/{p=1;print;next} p&&/^Memories used:/{p=0};p' | grep -E "Total" | grep -Eo "([0-9]+\.[0-9]+)"`
                      echo "$processor has clock period of = $period ps, area (excluding memory) = $area um^2"
                      runtime=`echo "$period*$cycle/1000" | bc`
                      echo "Runtime = $runtime ns ($period ps * $cycle)"
		  fi
               fi

               echo "$processor, $cycle, $period, $area" >> bench.csv
               
           fi
       done
    else
       for folder in $folders
       do
          for microtest in `ls sw/build/$folder/*.vmh`
          do
              microtest=$(basename "$microtest")
              microtest="${microtest%.*}"
              mkdir -p test_out/$folder
              echo "Running $folder $microtest on $processor"
              rm -f mem.vmh
              ln -s sw/build/$folder/$microtest.vmh mem.vmh
              if [ $VERBOSE -eq 1 ]; then
                  ./$processor 2>&1 | tee test_out/$folder/$microtest.out
              else
                  ./$processor &> test_out/$folder/$microtest.out
                  cat test_out/$folder/$microtest.out | sed -e 's/.*Dumping the.*/FAILED/' | grep -E ".*PASSED.*|.*FAILED.*"
              fi
          done
       done
    fi
done
