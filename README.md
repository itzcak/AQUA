# AQUA
AQUA is a novel bandwidth allocation scheme for QoS improvement, considering unbounded number of stream requirements. 
It operates on top of the current congestion control schemes.
AQUA incorporates several novel ideas to ensure that even under changing network conditions and higher number of streams, bandwidth requirements are satisfied. 
Real-world and lab experiments of AQUA’s implementation (as a QUIC module) show that adding AQUA significantly outperforms QUIC’s performance, even under
extreme congestion, while preserving high network utilization and stability.

# Implemantation
AQUA's implementation extends Google QUICHE and chromium project framework (a C++ implementation of QUIC).
We used Chromium version ID 407956543 from Nov 5th, 2021.
For Chromium project description see: https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md

We modified two main QUICHE's objects: (i) session object, and (ii) stream object. 
Time intervals properties are added to these two objects, for dynamic allocation. 
We also included parameters which capture the minimum and maximum requirements for each stream, network capacity estimation, and state.

3 files are included:
1. QUICHE diff file   - includes all code changes on QUICHE project
2. Chromium diff file - includes few changes on Chromium project
3. RunAquaTests.sh    - script for long amount of tests

# Evaluation
AQUA bandwidth allocation was examined for each stream in different scenairos.
The evaluation is done with quic_client and quic_server demo application from Chromium project.
Additional command line parameters are used to manipulate min/max BW definitions per stream.

Run quic_server and quic_client with simulated or real network in the middle.
RunAquaTests.sh automatic configures server and simulator to predefined combinations of streams and min/max configuration.
Also, configures simulator for predeined several network BW, and runs series of tests.
The output are csv files with lists of BW for each stream, for every second.

For example, we consider a scenario of 5 parallel streams, each with different minimum requirement levels:
10 Kbps, 100 Kbps, 1 Mbps, 10 Mbps, 100 Mbps. This senario captures heterogeneous stream applications in a variety of
fields, from conferences to medical procedures. 

# quic_server new parameters
Following command line parameters added to quic_server
1. stream_min_bw - Array of values for min BW (separated by comma) applied to connections according to open
2. stream_max_bw - Array of values for min BW (as above)
3. stream_priority - Array of priorities with boolen value 0 or 1, connections with 1 are prioritized.

In our example: Run command for 5 parallel connections 10k,100k,1m,10m,100m

Command line:    
'quic_server --quic_response_cache_dir=/home/maint/QuicPlayDir
        --certificate_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pem --key_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pkcs8
        --generate_dynamic_responses --stream_min_bw="11264,112640,1153434,11534340,115343400" --stream_max_bw="15360,153600,1572864,15728640,157286400"
 		     --stream_priority="1,1,1,1,0"'
    
# quic_client new parameters
Following command line parameters added to quic_client
1. Parallel - Enable several streams to run in parallel
2. Print_delay - Delay time between butes send periodic reports (default 1 second)

In our example:  Request 5 parallel connections (parameters defined by server)

Command line:      
'quic_client --host=10.10.2.2 --port=6121 --disable_certificate_verification --parallel --drop_response_body --print_delay=1000 --connection_options=QBIC
    http://www.example.org/10000000000 http://www.example.org/10000000000 http://www.example.org/10000000000
    http://www.example.org/10000000000 http://www.example.org/10000000000'
    
