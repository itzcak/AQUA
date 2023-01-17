# AQUA
Manage QUIC streams to get BW according to real per stream requirements

# What is the project?
Based on Google QUICHE and chromium project framework (especially Chromium version
on Nov the 5th, 2021 ID 407956543).
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



