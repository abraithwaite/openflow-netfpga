''' This file will create the necessary serial code for the netfpga
    for testing registers with modelsim and tcl. See tests for examples
    '''
from of_header import OFHeader, default_route
from of_update import write_table, read_table

cmp_mask = default_route()
cmp_mask = cmp_mask.build(OF_NW_DST = "0.0.0.0")

cmp_data = OFHeader()
cmp_data.makestruct()
cmp_data = cmp_data.build(OF_NW_DST = "192.168.11.1")

action = OFHeader()
action.OF_PADDING = 0x07
action.OF_PADDING2 = 0x00
action.OF_PADDING3 = 0x00
action.OF_IN_PORT = 0x0004
action.OF_DL_DST = (0x55, 0x55, 0xde, 0xad, 0xbe, 0xef)
action.OF_DL_SRC = (0xca, 0xfe, 0xde, 0xca, 0xde, 0x77)
action.makestruct()

for x in action.serialize_str(): print x,
print ""
for x in cmp_mask.serialize_str(): print x,
print ""
for x in cmp_data.serialize_str(): print x,
print ""
