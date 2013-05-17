from of_header import OFHeader, default_route
from of_update import write_table, read_table

print 'Row 1'
cmp_mask = default_route()
cmp_mask = cmp_mask.build(OF_NW_DST = "0.0.0.0")

cmp_data = OFHeader()
cmp_data.makestruct()
cmp_data = cmp_data.build(OF_NW_DST="192.168.1.4")

action = OFHeader()
action.OF_DL_DST=(0x00, 0x15, 0x17, 0x25, 0xd2, 0x76)
action.OF_PADDING = 0x03
action.OF_PADDING2 = 0x00
action.OF_PADDING3 = 0x00
action.OF_IN_PORT = 0xffff
action.makestruct()

write_table(0, cmp_data, cmp_mask, action)

read_table(0)

print 'Row 2'
cmp_mask = default_route()
cmp_mask = cmp_mask.build(OF_NW_DST = "0.0.0.0")

cmp_data = OFHeader()
cmp_data.makestruct()
cmp_data = cmp_data.build(OF_NW_DST="192.168.11.1")
# Source unecessary?

action = OFHeader()
action.OF_DL_DST=(0xd4, 0xbe, 0xd9, 0x4e, 0x32, 0xa6)
action.OF_PADDING = 0x03
action.OF_PADDING2 = 0x00
action.OF_PADDING3 = 0x00
action.OF_IN_PORT = 0xffff
action.makestruct()

write_table(1, cmp_data, cmp_mask, action)

read_table(1)

print 'Row 32'
cmp_mask = default_route()

cmp_data = OFHeader()
cmp_data.makestruct()

action = OFHeader()
action.OF_PADDING = 0x03
action.OF_PADDING2 = 0x00
action.OF_PADDING3 = 0x00
action.OF_IN_PORT = 0xffff
action.makestruct()

write_table(31, cmp_data, cmp_mask, action)

read_table(32)
