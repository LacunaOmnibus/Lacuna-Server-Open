#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl weekly_medals.pl
perl trelvestian/reset_essentia_veins.pl

