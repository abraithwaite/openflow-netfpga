restart

set module "matcher"
set cycles 32
set reg_addr_base 512
set reg_addr_width 29

# reg_data_in format:
# Data to return from CAM
# Mask for rule (1s are don't cares)
# data to look for.

set reg_data_in {cdab0400 563412ef 100f100f 0000100f 00080000 29203306 a80c2b7d 50baa1c0 00000000
                 cdab0400 563412ef 100f100f 0000100f 00080000 29203306 a80c2b7d 50baa1c0 00000000
                 cdab04ff 563412ef 100f100f 0000100f 00080000 29203306 a80c2b7d 50baa1c0 00000000}
                # ^ Start of packet                                             End of pkt  ^^ action

force -drive sim:/$module/clk 0 0, 1 {50 ps} -r 100
force -drive sim:/$module/reset 1'h1 0 -cancel 50

# Keep inputs at 0
force -drive sim:/$module/headers_valid 1'h0 0
force -drive sim:/$module/header_bus 264'h0 0

for {set i 0} {$i < $cycles} {incr i} {
    set val [expr $i * 100 + 55000]
    set reg_addr [expr $i * 4 + $reg_addr_base]
    set reg_data [lindex $reg_data_in $i]
    #set reg_rd_wr [lindex $reg_rd_wr_L_in $i]
    #set reg_req [lindex $reg_req_in $i]
    set start [expr 51+$val]
  
    if {$i < 27} {
        set reg_req 1
        set reg_rd_wr 0
    } else {
        set reg_req 0
        set reg_rd_wr 0
    }
    if {$i == 28} {
        set reg_req 1
        set reg_rd_wr 0
    }
        
    echo $start $reg_addr $reg_data
    force -drive sim:/$module/reg_addr_in 23'd$reg_addr $start
    force -drive sim:/$module/reg_data_in 32'h$reg_data $start
    force -drive sim:/$module/reg_rd_wr_L_in 1'h$reg_rd_wr $start
    force -drive sim:/$module/reg_req_in 1'h$reg_req $start
}

run
