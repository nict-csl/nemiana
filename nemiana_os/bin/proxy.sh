#!/usr/bin/env bash
#
# usage
#
# $0 log/log3.log
#
socat -v -lf$1 tcp-listen:2345,fork tcp-connect:localhost:1234 &>${1}_std.log

#/opt/rv32i/bin/riscv32-unknown-elf-gdb -i=mi /home/kanaya/src/hdl/poyo-v/sample14/app.elf

