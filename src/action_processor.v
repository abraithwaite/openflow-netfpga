///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: action_processor 2008-03-13 gac1 $
//
// Module: action_processor.v
// Project: NF2.1
// Description: defines a module for the user data path
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module action_processor
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter OF_ACTION_DATA_WIDTH = `OF_ACTION_DATA_WIDTH,
      parameter OF_ACTION_CTRL_WIDTH = `OF_ACTION_CTRL_WIDTH,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      // --- Interface to input fifo
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,

      // --- Interface to the matcher 
      input [`OF_ACTION_DATA_WIDTH-1:0]   action_data_bus,
      input [`OF_ACTION_CTRL_WIDTH-1:0]   action_ctrl_bus,
      input                               action_valid,

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

   reg                           in_fifo_rd_en;
   reg                           out_wr_int;

   wire [OF_ACTION_DATA_WIDTH-1:0]    in_action_data;
   wire [OF_ACTION_CTRL_WIDTH-1:0]    in_action_ctrl;

   //------------------------- Local assignments -------------------------------

   //------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) action_fifo (
      .din           ({action_ctrl_bus, action_data_bus}),   // Data in
      .wr_en         (in_wr),                // Write enable
      .rd_en         (in_fifo_rd_en),        // Read the next word
      .dout          ({in_action_ctrl, in_action_data}),
      .full          (),
      .nearly_full   (in_fifo_nearly_full),
      .prog_full     (),
      .empty         (in_fifo_empty),
      .reset         (reset),
      .clk           (clk)
   );

   //------------------------- Logic-------------------------------

   always @(*) begin
      // Default values
      out_wr_int = 0;
      in_fifo_rd_en = 0;

      if (!in_fifo_empty && out_rdy) begin
         out_wr_int = 1;
         in_fifo_rd_en = 1;
      end
   end


endmodule
