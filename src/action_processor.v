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
      output reg                          in_rdy,

      output reg [DATA_WIDTH-1:0]         out_data,
      output reg [CTRL_WIDTH-1:0]         out_ctrl,
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

   //------------------------- Local -------------------------------

   localparam  WAIT_LUT          = 1,
               DO_PORT           = 2,
               WAIT_EOP          = 0;

   //------------------------- Signals-------------------------------

   reg                           action_fifo_rd_en;
   reg                           out_wr_int;

   reg [1:0]                     state;

   wire [OF_ACTION_DATA_WIDTH-1:0]    in_action_data;
   wire [OF_ACTION_CTRL_WIDTH-1:0]    in_action_ctrl;


   //------------------------- Local assignments -------------------------------
   
   assign reg_req_out =     reg_req_in;
   assign reg_ack_out =     reg_ack_in;
   assign reg_rd_wr_L_out = reg_rd_wr_L_in;
   assign reg_addr_out =    reg_addr_in;
   assign reg_data_out =    reg_data_in;
   assign reg_src_out =     reg_src_in;


   //------------------------- Modules-------------------------------

   fallthrough_small_fifo #(
      .WIDTH(`OF_ACTION_DATA_WIDTH+`OF_ACTION_CTRL_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) action_fifo (
      .din           ({action_ctrl_bus, action_data_bus}),   // Data in
      .wr_en         (action_valid),                // Write enable
      .rd_en         (action_fifo_rd_en),        // Read the next word
      .dout          ({in_action_ctrl, in_action_data}),
      .full          (),
      .nearly_full   (action_fifo_nearly_full),
      .prog_full     (),
      .empty         (action_fifo_empty),
      .reset         (reset),
      .clk           (clk)
   );

   //------------------------- Logic-------------------------------

   always @(posedge clk) begin
      if(reset) begin
         action_fifo_rd_en <= 0;
         in_rdy <= 0;
         // Do stuff
      end
      else begin
         // Default Case
         out_data <= in_data;
         case(state)
            WAIT_LUT: begin
               if (!action_fifo_empty) begin
                  action_fifo_rd_en <= 1;
                  in_rdy <= 1;
                  state <= DO_PORT;
               end
            end
            DO_PORT: begin
               action_fifo_rd_en <= 0;
               if (in_ctrl == `IO_QUEUE_STAGE_NUM) begin
                  if (in_action_ctrl[0] & 1'h1) begin
                     out_data[63:48] <= action_data_bus[`OF_DST_PORT + `OF_DST_PORT_POS - 1: `OF_DST_PORT_POS];
                  end
                  state <= WAIT_EOP;
               end
            end
            WAIT_EOP: begin
               if (in_ctrl != 0) begin
                  if (!action_fifo_empty) begin
                     action_fifo_rd_en <= 1;
                     in_rdy <= 1;
                     state <= DO_PORT;
                  end
                  else begin
                     action_fifo_rd_en <= 0;
                     in_rdy <= 0;
                     state <= WAIT_LUT;
                  end
               end // in_ctrl != 0
            end // wait_eop
         endcase
      end // else
   end // posedge clk

endmodule
