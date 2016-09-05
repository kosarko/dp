#!/bin/bash

#export train_cmd="run.pl"
#export decode_cmd="run.pl"

export train_cmd="queue.pl -m abe -M kosarko@ufal.mff.cuni.cz -l mem_free=4g,h_vmem=8g,act_mem_free=4g,arch=*64* -q ms-all.q"
export decode_cmd="queue.pl -m abe -M kosarko@ufal.mff.cuni.cz -l mem_free=4g,h_vmem=8g,act_mem_free=4g,arch=*64* -q ms-all.q"

export njobs=20
