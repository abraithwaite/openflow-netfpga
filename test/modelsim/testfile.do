restart
force -freeze sim:/header_parser/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/header_parser/reset 1'h1 0 -cancel 75
force -freeze sim:/header_parser/in_wr 1'h1 75 -cancel 975

force -freeze sim:/header_parser/in_data 64'h0000000000040000 75 -cancel 175
force -freeze sim:/header_parser/in_ctrl 8'hff 75 -cancel 175
force -freeze sim:/header_parser/in_data 64'h0bae6648b13bf3b5 176 -cancel 275
force -freeze sim:/header_parser/in_ctrl 8'h00 176 -cancel 275
force -freeze sim:/header_parser/in_data 64'hd0326e7808000923 276 -cancel 375
force -freeze sim:/header_parser/in_ctrl 8'h00 276 -cancel 375
force -freeze sim:/header_parser/in_data 64'h0000000000000006 376 -cancel 475
force -freeze sim:/header_parser/in_ctrl 8'h00 376 -cancel 475
force -freeze sim:/header_parser/in_data 64'h0000e3bac4bf1028 476 -cancel 575
force -freeze sim:/header_parser/in_ctrl 8'h00 476 -cancel 575
force -freeze sim:/header_parser/in_data 64'h00acf2dfc58b0000 576 -cancel 675
force -freeze sim:/header_parser/in_ctrl 8'h00 576 -cancel 675
force -freeze sim:/header_parser/in_data 64'h0000f2dfc58b0000 676 -cancel 775
force -freeze sim:/header_parser/in_ctrl 8'h00 676 -cancel 775
force -freeze sim:/header_parser/in_data 64'h0000f2dfc58b0000 776 -cancel 875
force -freeze sim:/header_parser/in_ctrl 8'h02 776 -cancel 875