set module "matcher"
set data_in {00000000000400000bae6648b13bf3b5d0326e78080009230000000000000006AB
00000000000400000bae6648b13bf3b5d0326e78080009230000000000000006AB
00000000000400000bae6648b13bf3b5d0326e78080009230000000000000006AB
00000000000400000bae6648b13bf3b5d0326e78080009230000000000000006AB
00000000000400000bae6648b13bf3b5d0326e78080009230000000000000006AB
}
set reg_addr_in {abc abc abc abc abc abc}
set reg_data_in {abcd abcd abcd abcd abcd abcd abcd}

force -freeze sim:/$module/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/$module/reset 1'h1 0 -cancel 75
force -freeze sim:/$module/in_wr 1'h1 75 -cancel 975

for {set i 0} {$i < $cycles} {incr i} {
    set val [expr $i * 100]
    set data_word [lindex $data_in $i]
    set ctrl_word [lindex $ctrl_in $i]
    set reg_addr [lindex $reg_addr_in $i]
    set reg_data [lindex $reg_data_in $i]
    set start [expr 76 + val]
    set stop [expr 175 + val]
    echo $start $stop $data_word $ctrl_word $reg_addr $reg_data
    force -freeze sim:/$module/header_bus 264'h$data_word $start -cancel $stop
    force -freeze sim:/$module/headers_valid 1'b1 $start -cancel $stop
    force -freeze sim:/$module/reg_addr_in 23'h$reg_addr $start -cancel $stop
    force -freeze sim:/$module/reg_data_in 32'h$reg_data $start -cancel $stop
}
