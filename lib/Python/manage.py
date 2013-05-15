from of_header import OFHeader, default_route
from of_update import write_table, read_table

cmp_mask = default_route()
cmp_mask = cmp_mask.build(OF_NW_DST = "0.0.0.0")

cmp_data = OFHeader()
cmp_data.makestruct()
cmp_data = cmp_data.build(OF_NW_DST = "192.168.11.1")

action = OFHeader()
action.OF_PADDING = 0xff
action.OF_PADDING2 = 0xff
action.OF_PADDING3 = 0xff
action.OF_IN_PORT = 0x0004
action.makestruct()

write_table(28, cmp_data, cmp_mask, action)

read_table(28)
#print ''
#read_table(31)
