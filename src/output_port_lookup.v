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

   //------------------------- Signals-------------------------------
   wire [CTRL_WIDTH-1:0]            ap_in_ctrl;
   wire [DATA_WIDTH-1:0]            ap_in_data;
   wire                             ap_in_wr;
   wire                             ap_in_rdy;
   wire [`OF_ACTION_DATA_WIDTH-1:0]    ap_in_act_data;
   wire [`OF_ACTION_CTRL_WIDTH-1:0]    ap_in_act_ctrl;
   wire                                ap_in_act_valid;

   wire [`OF_HEADER_REG_WIDTH-1:0]  mtch_in_header;
   wire                             mtch_in_header_valid;

   wire                             mtch_in_reg_req;
   wire                             mtch_in_reg_ack;
   wire                             mtch_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   mtch_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  mtch_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     mtch_in_reg_src;


   header_parser #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) header_parser (
      .in_data              (in_data),
      .in_ctrl              (in_ctrl),
      .in_wr                (in_wr),

      .header_bus           (mtch_in_header),
      .headers_valid        (mtch_in_header_valid),

      // --- Register interface
      .reg_req_in           (reg_req_in),
      .reg_ack_in           (reg_ack_in),
      .reg_rd_wr_L_in       (reg_rd_wr_L_in),
      .reg_addr_in          (reg_addr_in),
      .reg_data_in          (reg_data_in),
      .reg_src_in           (reg_src_in),

      .reg_req_out          (mtch_in_reg_req),
      .reg_ack_out          (mtch_in_reg_ack),
      .reg_rd_wr_L_out      (mtch_in_reg_rd_wr_L),
      .reg_addr_out         (mtch_in_reg_addr),
      .reg_data_out         (mtch_in_reg_data),
      .reg_src_out          (mtch_in_reg_src),

      .clk                  (clk),
      .reset                (reset)
   );

   matcher #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) matcher (

      // Input from header parser
      .header_bus           (mtch_in_header),
      .headers_valid        (mtch_in_header_valid),

      // Output to action processor
      .action_data_bus      (ap_in_act_data),
      .action_ctrl_bus      (ap_in_act_ctrl),
      .action_valid         (ap_in_act_valid),

      // --- Register interface
      .reg_req_in           (mtch_in_reg_req),
      .reg_ack_in           (mtch_in_reg_ack),
      .reg_rd_wr_L_in       (mtch_in_reg_rd_wr_L),
      .reg_addr_in          (mtch_in_reg_addr),
      .reg_data_in          (mtch_in_reg_data),
      .reg_src_in           (mtch_in_reg_src),

      .reg_req_out          (reg_req_out),
      .reg_ack_out          (reg_ack_out),
      .reg_rd_wr_L_out      (reg_rd_wr_L_out),
      .reg_addr_out         (reg_addr_out),
      .reg_data_out         (reg_data_out),
      .reg_src_out          (reg_src_out),

      .clk                  (clk),
      .reset                (reset)
   );

   holding_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) holding_fifo (

      .in_data              (in_data),
      .in_ctrl              (in_ctrl),
      .in_wr                (in_wr),
      .in_rdy               (in_rdy),

      .out_data             (ap_in_data),
      .out_ctrl             (ap_in_ctrl),
      .out_wr               (ap_in_wr),
      .out_rdy              (ap_in_rdy),

      .clk                  (clk),
      .reset                (reset)

   );

   action_processor #(
      .DATA_WIDTH(DATA_WIDTH),
      .CTRL_WIDTH(CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) action_processor (
      // Input from matcher
      .action_data_bus      (ap_in_act_data),
      .action_ctrl_bus      (ap_in_act_ctrl),
      .action_valid         (ap_in_act_valid),

      // Input from holding FIFO
      .in_data              (ap_in_data),
      .in_ctrl              (ap_in_ctrl),
      .in_wr                (ap_in_wr),
      .in_rdy               (ap_in_rdy),

      // Output to output queues
      .out_data             (out_data),
      .out_ctrl             (out_ctrl),
      .out_wr               (out_wr),
      .out_rdy              (out_rdy),

      .clk                  (clk),
      .reset                (reset)

   );

endmodule
