import struct
import reg_defines_openflow as rd
from hwReg import writeReg
from of_header import OFHeader
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

    if 0 > position or position > rd.OF_NUM_ENTRIES():
        raise Exception("Invalid position argument")

    cmp_din = struct.pack("I"*OF_LUT_CMP_WORDS, wr_cmp_data)
    cmp_mask = struct.pack("I"*OF_LUT_CMP_WORDS, wr_cmp_mask)

    #TODO: You are here!
    #TODO: Finish this function







