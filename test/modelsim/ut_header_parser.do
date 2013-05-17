
set cycles 8
set data_list {0000000000040000 0bae6648b13bf3b5 d0326e7808000923 0000000000000006
0000e3bac4bf1028 00acf2dfc58b0000 0000f2dfc58b0000 0000f2dfc58b0000}
set ctrl_list {ff 00 00 00 00 00 00 02}

restart
force -freeze sim:/header_parser/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/header_parser/reset 1'h1 0 -cancel 75
force -freeze sim:/header_parser/in_wr 1'h1 75 -cancel 975

for {set i 0} {$i < $cycles} {incr i} {
    set val [expr $i * 100]
    set data_word [lindex $data_list $i]
    set ctrl_word [lindex $ctrl_list $i]
    set start [expr 76 + val]
    set stop [expr 175 + val]
    echo $data_word $start $stop
    force -freeze sim:/header_parser/in_data 64'h$data_word $start -cancel $stop
    force -freeze sim:/header_parser/in_ctrl 8'h$ctrl_word $start -cancel $stop
}

