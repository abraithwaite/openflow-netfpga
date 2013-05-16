restart

set module "output_port_lookup"
set cycles 32
set matcher_reg_addr_base 1024

# reg_data_in format:
# Data to return from CAM
# Mask for rule (1s are don't cares)
# data to look for.

set reg_data_in {de770004 cafedeca deadbeef 00005555 00000000 00000000 00000000 00000000 00000700
                 ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff 000000ff ffffff00 000000ff
                 00000000 00000000 00000000 00000000 00000000 00000000 a80b0100 000000c0 00000000}

                #    IOHDR           DL_DST   SRCH   SRCL  type h   len/id  foff ttl/proto
                #v--------------v v----------vv--v v------vv--vvvvv v------vv--vv--v
set pkt_data_in {0000000000040000 ffffffffffff0000 d0326e7808000923 0000000000000006
                 0000e3bac4bfc0a8 0b01f2dfc58b0000 0000f2dfc58b0000 0000f2dfc58b0000}
                #^--^^------^^--- ---^
                #      IPSRC   IPDST
set pkt_ctrl_in {ff 00 00 00 00 00 00 02}

force -drive sim:/$module/clk 0 0, 1 {50 ps} -r 100
force -drive sim:/$module/reset 1'h1 0 -cancel 50

for {set i 0} {$i < $cycles} {incr i} {
    set val [expr $i * 100 + 55000]
    set start [expr 51+$val]

    set reg_addr [expr $i * 4 + $matcher_reg_addr_base]
    set reg_data [lindex $reg_data_in $i]
  
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


force -drive sim:/$module/out_rdy 1'h1 0
for {set i 0} {$i < $cycles} {incr i} {
    set val [expr $i * 100 + 100000]
    set start [expr 51+$val]

    set pkt_data [lindex $pkt_data_in $i]
    set pkt_ctrl [lindex $pkt_ctrl_in $i]
        
    if {$i < 8} {
        set in_wr 1
    } else {
        set in_wr 0
    }

    force -drive sim:/$module/in_data 64'h$pkt_data $start
    force -drive sim:/$module/in_ctrl 8'h$pkt_ctrl $start
    force -drive sim:/$module/in_wr 1'h$in_wr $start
}

