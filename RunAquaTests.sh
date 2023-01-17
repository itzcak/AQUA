#!/bin/bash 

DIRNAME="Tests_$(date +%d_%m_%Y_%H_%M_%S)"
SERVER_ADDR="10.10.2.2"
SIMULATOR_ADDR="10.10.2.1"
TEST_PLACE="Lab"
MIN_VALUES="11264,112640,1153434,11534340,115343400"
MAX_VALUES="157286400,157286400,157286400,157286400,157286400"
#MAX_VALUES="15360,153600,1572864,1572864000,157286400"
#MAX_VALUES="15360,153600,1572864,15728640,157286400"
PRIORITY_VALUES="1,1,1,1,0"
NO_CONGESTION_BW=140
ON_LIMIT_BW=125
LOW_CONGESTION_BW=100
#HIGH_CONGESTION_BW=50
HIGH_CONGESTION_BW=47

#Parameters
# 1) stream_min_bw parameter i.e. "10000,100000,1000000,10000000,100000000"
# 2) stream_max_bw parameter i.e. "15000,150000,1500000,15000000,150000000"
# 3) stream priority parameter i.e. "1,1,0,0,0"

StopServer()
{
    ssh maint@$SERVER_ADDR killall quic_server &> /dev/null
}

#Parameters
# 1) stream min BW: Array of min BW values for all streams (separated by comma)
# 2) stream max BW: Array of max BW values for all streams (separated by comma)
# 3) Streams priorityL Array of flags (0 or 1) which represent stream priorities (separated by comma)
# 4) Set "--use_default_prioritization"

StartServer()
{
    StopServer
    sleep 2
    ssh maint@$SERVER_ADDR "/home/maint/chromium/src/out/Default/quic_server --quic_response_cache_dir=/home/maint/QuicPlayDir\
	--certificate_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pem --key_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pkcs8\
	--generate_dynamic_responses --stream_min_bw=\"$1\" --stream_max_bw=\"$2\" --stream_priority=\"$3\" $4" &> /dev/null &
}

#parameters
# 1) BW in mbps
# 2) Delay in ms (RTT = Delay *2)
# 3) Packet loss percent
# 4) Queue size for ms BW (i.e queue length 40 will hold BW for 40 ms)

ConfigSimulator()
{
    ssh root@$SIMULATOR_ADDR ./change $1 $2 $3 $4
}

#Parameters
# 1) Number of streams (currently must be 5)
# 2) Congestion control code: "QBIC", "RENO", "TBBR" (BBR V1), "B2ON" (BBR V2)
# 3) File name to write results
STREAM_1="http://www.example.org/10000000000 "
RunTest()
{
    NUM_STREAMS=$1
    STREAMS=""
    while [ $NUM_STREAMS -gt 0 ]
    do
	STREAMS+="${STREAM_1}"
	((NUM_STREAMS--))
    done
    echo "Running Test for $3"
    script -f client_output.txt -c "timeout 31 ../quic_client --host=$SERVER_ADDR --port=6121 --disable_certificate_verification --parallel --drop_response_body --print_delay=1000 --connection_options=$2 $STREAMS"
    awk 'BEGIN\
          {\
	      n=1\
	  }\
          /streams/\
	  {\
	      A[n][1]=$4;\
	      A[n][2]=$6;\
	      A[n][3]=$8;\
	      A[n][4]=$10;\
	      A[n++][5]=$12;\
	  }\
          END\
	  {\
	      printf("100m,10m,1m,100k,10k\n");\
	      for(i=2;i<n;i++)\
	      {\
		  for (i2=1; i2 <=5; i2++)\
		  	{\
			    B[i2]=(A[i][i2] - A[i-1][i2])*8;\
	      		}\
	          printf("%u,%u,%u,%u,%u\n", B[1], B[2], B[3], B[4], B[5]);\
	      }\
	  }' client_output.txt | tee "$3.csv"
     rm client_output.txt
     sleep 2
}

#Parameters

# 1) File name: Name of output file(no extention)
# 2) Congestion control string
Run10Tests()
{
    for i in {1..50}
    do
       RunTest 5 $2 "$1_$i"
    done
}

#Parameters
# 1) File name: Name of output file(no extention. no congestion and priority type)
# 2) Do run proitized? 0 or 1
RunCongestionPriorityRound()
{
    
    StartServer $MIN_VALUES $MAX_VALUES "" --use_default_prioritization
    sleep 1
    Run10Tests "$1_NoAQUA_BBR_NoPriority" "B2ON"
    Run10Tests "$1_NoAQUA_CUBIC_NoPriority" "QBIC"
    StartServer $MIN_VALUES $MAX_VALUES ""
    sleep 1
    Run10Tests "$1_AQUA_BBR_NoPriority" "B2ON"
    Run10Tests "$1_AQUA_CUBIC_NoPriority" "QBIC"
    if [ $2 -gt 0 ]; then
    	StartServer $MIN_VALUES $MAX_VALUES "$PRIORITY_VALUES"
    	sleep 1
    	Run10Tests "$1_AQUA_BBR_Priority" "B2ON"
    	Run10Tests "$1_AQUA_CUBIC_Priority" "QBIC"
    fi
}

#Parameters
# 1) BW in mbps
# 2) Do run prioritized? 0 or 1
# 3) File name: Name of output file(no extention, no congestion, no priority type, no buffer info)  
RunSimulationRound()
{
    ConfigSimulator "$1 10 0 4"
    RunCongestionPriorityRound "$3_0.2RttBuffer" $2
    ConfigSimulator "$1 10 0 10"
    RunCongestionPriorityRound "$3_0.5RttBuffer" $2
    ConfigSimulator "$1 10 0 20"
    RunCongestionPriorityRound "$3_1RttBuffer" $2
    ConfigSimulator "$1 10 0 40"
    RunCongestionPriorityRound "$3_2RttBuffer" $2
    ConfigSimulator "$1 10 0 6"
    RunCongestionPriorityRound "$3_0.3RttBuffer" $2
    ConfigSimulator "$1 10 0 10"
    RunCongestionPriorityRound "$3_0.5RttBuffer" $2
    ConfigSimulator "$1 10 0 20"
    RunCongestionPriorityRound "$3_1RttBuffer" $2
    ConfigSimulator "$1 10 0 40"
    RunCongestionPriorityRound "$3_2RttBuffer" $2
    ConfigSimulator "$1 10 0 100"
    RunCongestionPriorityRound "$3_5RttBuffer" $2
}

mkdir "$DIRNAME"
cd "$DIRNAME"

RunSimulationRound $NO_CONGESTION_BW 0 $TEST_PLACE"_NoCongestion140mbps" 
RunSimulationRound $ON_LIMIT_BW 1 $TEST_PLACE"_Congestion125mbps" 
RunSimulationRound $LOW_CONGESTION_BW 1 $TEST_PLACE"_Congestion100mbps" 
RunSimulationRound $HIGH_CONGESTION_BW 1 $TEST_PLACE"_Congestion50mbps" 
RunSimulationRound $HIGH_CONGESTION_BW 1 $TEST_PLACE"_Congestion45mbps" 
