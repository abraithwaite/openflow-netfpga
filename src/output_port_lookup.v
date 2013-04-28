///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: output_port_lookup 2008-03-13 gac1 $
//
// Module: output_port_lookup.v
// Project: NF2.1
// Description: defines a module for the user data path
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module output_port_lookup
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,

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

   header_parser #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH)
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
   ) header_parser (
      .in_data              (in_data),
      .in_ctrl              (in_ctrl),
      .in_wr                (in_wr),
      .in_rdy               (in_rdy),

      .header_bus           (),
      .headers_valid        (),

      .clk                  (clk),
      .reset                (reset)
   );

   holding_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH)
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
   ) holding_fifo (
      .in_data              (in_data),
      .in_ctrl              (in_ctrl),
      .in_wr                (in_wr),
      .in_rdy               (in_rdy),

      .out_data             (ap_in_data),
      .out_ctrl             (ap_in_ctrl),
      .out_wr               (ap_in_wr),
      .out_rdy              (ap_in_rdy),

      .header_bus           (),
      .headers_valid        (),

      .clk                  (clk),
      .reset                (reset)
   );

   action_processor #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH)
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
   ) action_processor (
      .in_data              (ap_in_data),
      .in_ctrl              (ap_in_ctrl),
      .in_wr                (ap_in_wr),
      .in_rdy               (ap_in_rdy),

      .out_data             (out_data),
      .out_ctrl             (out_ctrl),
      .out_wr               (out_wr),
      .out_rdy              (out_rdy),

      .header_bus           (),
      .headers_valid        (),

      .clk                  (clk),
      .reset                (reset)
   );

endmodule
