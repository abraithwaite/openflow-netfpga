import struct
import time
import reg_defines_openflow as rd
from hwReg import writeReg, readReg
from of_header import OFHeader, OF_STRUCT
from math import ceil

# Defines
OF_LUT_DATA_WORDS = ceil((rd.OF_ACTION_CTRL_WIDTH() + rd.OF_ACTION_DATA_WIDTH()) / rd.CPCI_NF2_DATA_WIDTH())
OF_LUT_CMP_WORDS = ceil(rd.OF_HEADER_REG_WIDTH() / rd.CPCI_NF2_DATA_WIDTH())
OF_LUT_DATA_OFF = 0 # LUT data at register base
OF_LUT_CMP_OFF = OF_LUT_DATA_WORDS
OF_LUT_CMP_DATA_OFF = OF_LUT_DATA_WORDS + OF_LUT_CMP_WORDS

# Arguments in this function not to be confused with their verilog counterparts
# They have the same name for different purpopses.  python wr_cmp_data != verilog wr_cmp_data
def write_table(position, wr_cmp_data, wr_cmp_mask, wr_action_data, wr_action_ctrl):
    '''
        position: priority in table (0-31, 0 highest priority)
        wr_cmp_data: headers to look for
        wr_cmp_mask: what to mask against (1s are don't care)
        wr_action_data: headers to be applied
        wr_action_ctrl: numeric mask of fields to modify
    '''

    if type(wr_cmp_data) is not OFHeader:
        raise Exception("Must be OFHeader type")

    if type(wr_cmp_mask) is not OFHeader:
        raise Exception("Must be OFHeader type")

    if type(wr_action_data) is not OFHeader:
        raise Exception("Must be OFHeader type")

    if not (0 <= position < rd.OF_NUM_ENTRIES()):
        raise Exception("Invalid position argument")

    cmp_din = wr_cmp_mask.serialize()
    cmp_mask = wr_cmp_data.serialize()
    action_data = wr_action_data.serialize()

    for i in xrange(9):
        writeReg(rd.MATCHER_LUT_DATA_0_REG()+4*i, action_data[i])
        writeReg(rd.MATCHER_TCAM_DATA_0_REG()+4*i, cmp_din[i])
        writeReg(rd.MATCHER_TCAM_MASK_0_REG()+4*i, cmp_mask[i])

    # Dummy write to write reg for tcam push
    time.sleep(1)
    writeReg(rd.MATCHER_WRITE_REG_REG(), position)
    print [hex(x) for x in cmp_din]

def read_table(index):
    writeReg(rd.MATCHER_READ_REG_REG(), index)
    time.sleep(2)

    vals, vals2, vals3= [], [], []
    for j in xrange(9):
        vals.append(readReg(rd.MATCHER_LUT_DATA_0_REG()+4*j))
        vals2.append(readReg(rd.MATCHER_TCAM_DATA_0_REG()+4*j))
        vals3.append(readReg(rd.MATCHER_TCAM_MASK_0_REG()+4*j))
    print [hex(x) for x in vals]
    print [hex(x) for x in vals2]
    print [hex(x) for x in vals3]
    tot = [vals, vals2, vals3]
    for k in xrange(3):
        mydata = struct.pack("I"*9, *tot[k])
        of_h = OFHeader(mydata)

        for x in OF_STRUCT:
            print x[0], of_h.pretty.get(x[0], -1)

        print ""


act_data, cmp_data, cmp_mask = OFHeader(), OFHeader(), OFHeader()
act_data.build(OF_IN_PORT=1, OF_DL_SRC=(0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x00), OF_TP_DST=0xDACF, OF_NW_DST="255.192.0.55")
write_table(2, act_data, act_data, act_data, None)

time.sleep(1)
read_table(2)
