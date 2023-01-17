# AQUA
Manage QUIC streams to get BW according to real per stream requirements

# What is the project?
Based on Google QUICHE and chromium project framework (especially Chromium version on Nov the 5th, 2021 ID 407956543).
See project description here: https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md 

Streams are configured from application level with min and max BW requirements.
QUIC protocol level divides BW according to requirements.

3 files are included:
1. QUICHE diff file    includes all code changes on QUICHE project
2. Chromium diff file  includes few changes
3. RunAquaTests.sh     script for long amount of tests

# Evaluation
The evaluation is done with quic_client and quic_server demo application from Chromium project.
Additional command line parameters are used to manipulate min/max BW definitions per stream.

Run quic_server and quic_client with simulated or real network in the middle.
RunAquaTests.sh automatic configures server and simulator to predefined combinations of streams and min/max configuration.
Also, configures simulator for predeined several network BW, and runs series of tests.
The output is csv files with lists of BW per second per stream.

# Server new parameters
Following command line parameters added to quic_server
1. stream_min_bw  Array of values for min BW (separated by comma) applied to connections according to open
2. stream_max_bw  Array of values for min BW (as above)
3. stream_priority Array of priorities with boolen value 0 or 1, connections with 1 are prioritized.

Server example: Run command for 5 parallel connections 10k,100k,1m,10m,100m

 /home/maint/chromium/src/out/Default/quic_server --quic_response_cache_dir=/home/maint/QuicPlayDir
        --certificate_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pem --key_file=/home/maint/chromium/src/net/tools/quic/certs/out/leaf_cert.pkcs8
        --generate_dynamic_responses --stream_min_bw="11264,112640,1153434,11534340,115343400" --stream_max_bw="15360,153600,1572864,15728640,157286400"
 		     --stream_priority="1,1,1,1,0"
    
# Client new parameters
Following command line parameters added to quic_client
1. parallel  Enable several streams to run in parallel
2. print_delay Delay time between butes send periodic reports (default 1 second)

Client example:  Request 5 paralel connections (parameters defined by server)

 ../quic_client --host=10.10.2.2 --port=6121 --disable_certificate_verification --parallel --drop_response_body --print_delay=1000 --connection_options=QBIC
    http://www.example.org/10000000000 http://www.example.org/10000000000 http://www.example.org/10000000000
    http://www.example.org/10000000000 http://www.example.org/10000000000
    
