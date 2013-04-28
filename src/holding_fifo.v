///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: holding_fifo 2008-03-13 gac1 $
//
// Module: holding_fifo.v
// Project: NF2.1
// Description: defines a module for the user data path
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module holding_fifo
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

      // misc
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   `LOG2_FUNC

   //------------------------- Signals-------------------------------

   wire [DATA_WIDTH-1:0]         in_fifo_data;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl;

   wire                          in_fifo_nearly_full;
   wire                          in_fifo_empty;

   reg                           in_fifo_rd_en;
   reg                           out_wr_int;


   //------------------------- Local assignments -------------------------------

   assign in_rdy     = !in_fifo_nearly_full;
   assign out_wr     = out_wr_int;
   assign out_data   = in_fifo_data;
   assign out_ctrl   = in_fifo_ctrl;


   //------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(6)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),   // Data in
      .wr_en         (in_wr),                // Write enable
      .rd_en         (in_fifo_rd_en),        // Read the next word
      .dout          ({in_fifo_ctrl, in_fifo_data}),
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
