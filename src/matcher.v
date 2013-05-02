///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: matcher 2008-03-13 gac1 $
//
// Module: matcher.v
// Project: NF2.1
// Description: defines a module for the user data path
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module matcher
   #(
      parameter DATA_WIDTH = `OF_ACTION_DATA_WIDTH,
      parameter CTRL_WIDTH = `OF_ACTION_CTRL_WIDTH,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      // --- Interface to the header parser
      input [`OF_HEADER_REG_WIDTH-1:0]       header_bus,
      input                                  headers_valid,

      // --- Interface to the action processor
      output  [`OF_ACTION_DATA_WIDTH-1:0] action_data_bus,
      output  [`OF_ACTION_CTRL_WIDTH-1:0] action_ctrl_bus,
      output                              action_valid,
      output                              action_hit,

      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   `LOG2_FUNC
   `CEILDIV_FUNC

   //------------------------- Local assignments -------------------------------

   localparam MATCHER_ADDR_BITS = log2(`OF_NUM_ENTRIES);
   localparam MATCHER_NUM_WORDS = ceildiv(`OF_HEADER_REG_WIDTH, `CPCI_NF2_DATA_WIDTH);

   //------------------------- Signals-------------------------------

   
   // --- LUT <-> CAM interface

   wire                             cam_busy;
   wire                             cam_match;

   wire [`OF_NUM_ENTRIES-1:0]       cam_match_addr;
   wire [`OF_HEADER_REG_WIDTH-1:0]  cam_din, cam_data_mask;
   wire [`OF_HEADER_REG_WIDTH-1:0]  cam_cmp_din, cam_cmp_data_mask;
   wire                             cam_we;
   wire [MATCHER_ADDR_BITS-1:0]     cam_wr_addr;
   
   // --- Breaking up the address

   wire [MATCHER_NUM_WORDS-1:0]     cam_busy_itr;
   wire [MATCHER_NUM_WORDS-1:0]     cam_match_itr;

   //wire [`OF_NUM_ENTRIES-1:0]       cam_match_addr_itr[MATCHER_NUM_WORDS-1:0];
   wire [MATCHER_NUM_WORDS-1:0]     cam_match_addr_bus_itr[`OF_NUM_ENTRIES-1:0];
   wire [`OF_NUM_ENTRIES-1:0]       cam_din_itr[MATCHER_NUM_WORDS-1:0];
   wire [`OF_NUM_ENTRIES-1:0]       cam_data_mask_itr[MATCHER_NUM_WORDS-1:0];
   wire [`OF_NUM_ENTRIES-1:0]       cam_cmp_din_itr[MATCHER_NUM_WORDS-1:0];
   wire [`OF_NUM_ENTRIES-1:0]       cam_cmp_data_mask_itr[MATCHER_NUM_WORDS-1:0];

   //------------------------- Modules-------------------------------

   unencoded_cam_lut_sm
   #(
      .CMP_WIDTH(`OF_HEADER_REG_WIDTH),
      .DATA_WIDTH(`OF_ACTION_DATA_WIDTH + `OF_ACTION_CTRL_WIDTH),
      .TAG(`MATCHER_BLOCK_ADDR),
      .LUT_DEPTH(`OF_NUM_ENTRIES),
      .REG_ADDR_WIDTH(`MATCHER_REG_ADDR_WIDTH)
   )
   unencoded_cam_lut_sm
   (
      .lookup_req          (headers_valid),
      .lookup_cmp_data     (header_bus),
      .lookup_cmp_dmask    ({`OF_HEADER_REG_WIDTH{1'b0}}),

      .lookup_ack          (action_valid),
      .lookup_hit          (action_hit),
      .lookup_data         ({action_ctrl_bus, action_data_bus}),
      .lookup_address      (), // Unused?

      .reg_req_in          (reg_req_in),
      .reg_ack_in          (reg_ack_in),
      .reg_rd_wr_L_in      (reg_rd_wr_L_in),
      .reg_addr_in         (reg_addr_in),
      .reg_data_in         (reg_data_in),
      .reg_src_in          (reg_src_in),

      .reg_req_out         (reg_req_out), 
      .reg_ack_out         (reg_ack_out), 
      .reg_rd_wr_L_out     (reg_rd_wr_L_out),
      .reg_addr_out        (reg_addr_out),
      .reg_data_out        (reg_data_out),
      .reg_src_out         (reg_src_out), 

      .cam_busy            (cam_busy),
      .cam_match           (cam_match),
      .cam_match_addr      (cam_match_addr),

      .cam_din              (cam_din),
      .cam_data_mask        (cam_data_mask),
      .cam_cmp_din          (cam_cmp_din),
      .cam_cmp_data_mask    (cam_cmp_data_mask),
      .cam_we               (cam_we),
      .cam_wr_addr          (cam_wr_addr),

      .clk                 (clk),
      .reset               (reset)
   );

   generate
      genvar i, j;
      for ( i = 0; i < MATCHER_NUM_WORDS; i = i + 1 ) begin:cam_gen

         wire [`OF_NUM_ENTRIES -1 : 0] cam_match_addr_tmp;
         for ( j = 0; j < `OF_NUM_ENTRIES; j = j + 1 ) begin:cam_match_bit_gen
            assign cam_match_addr_bus_itr[j][i] = cam_match_addr_tmp[j];
         end
         srl_cam_unencoded_32x32 srl_cam_unencoded
         (
            // --- Inputs
            .din              (cam_din_itr[i]),
            .data_mask        (cam_data_mask_itr[i]),
            .cmp_din          (cam_cmp_din_itr[i]),
            .cmp_data_mask    (cam_cmp_data_mask_itr[i]),

            .we               (cam_we),
            .wr_addr          (cam_wr_addr),

            // --- Outputs
            .busy             (cam_busy_itr[i]),
            .match            (cam_match_itr[i]),
            .match_addr       (cam_match_addr_tmp),

            .clk              (clk)
         );

         // 32 from CAM size
         if (i == MATCHER_NUM_WORDS - 1) begin
            assign cam_din_itr[i] = cam_din[`OF_HEADER_REG_WIDTH - 1: 32*i];
            assign cam_data_mask_itr[i] = cam_din[`OF_HEADER_REG_WIDTH - 1: 32*i];
            assign cam_cmp_din_itr[i] = cam_din[`OF_HEADER_REG_WIDTH - 1: 32*i];
            assign cam_cmp_data_mask_itr[i] = cam_din[`OF_HEADER_REG_WIDTH - 1: 32*i];
         end
         else begin
            assign cam_din_itr[i] = cam_din[32*i + 31 : 32*i];
            assign cam_data_mask_itr[i] = cam_din[32*i + 31 : 32*i];
            assign cam_cmp_din_itr[i] = cam_din[32*i + 31 : 32*i];
            assign cam_cmp_data_mask_itr[i] = cam_din[32*i + 31 : 32*i];
         end
      end

      for ( j = 0; j < MATCHER_NUM_WORDS; j = j + 1 ) begin:cam_match_addr_gen
         assign cam_match_addr[j] = &cam_match_addr_bus_itr[j];
      end
      assign cam_busy = |cam_busy_itr;
   endgenerate

   //------------------------- Logic-------------------------------

endmodule
