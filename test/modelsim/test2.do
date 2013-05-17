
set cycles 8
set data_list {0000000000040000 0bae6648b13bf3b5 d0326e7808000923 0000000000000006
0000e3bac4bf1028 00acf2dfc58b0000 0000f2dfc58b0000 0000f2dfc58b0000}

restart
force -freeze sim:/header_parser/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/header_parser/reset 1'h1 0 -cancel 75
force -freeze sim:/header_parser/in_wr 1'h1 75 -cancel 975

for {set i 0} {$i < $cycles} {incr i} {
    set word [lindex $data_list $i]
    set start [expr 76 + $i * 100]
    set stop [expr 175 + $i * 100]
    echo "in loop $i"
    echo $word $start $stop
    force -freeze sim:/header_parser/in_data 64'h[lindex $data_list $i] $start -cancel $stop
}


