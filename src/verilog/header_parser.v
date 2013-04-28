///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
//
// Module: header_parser.v
// Project: NF3.0.1
// Description: contains all the user instantiated modules
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module header_parser
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_ADDR_WIDTH = `UDP_REG_ADDR_WIDTH,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      // --- Interface to the previous stage
      input  [DATA_WIDTH-1:0]                in_data,
      input  [CTRL_WIDTH-1:0]                in_ctrl,
      input                                  in_wr,

      // --- Interface to the next stage
      output reg [`OF_HEADER_REG_WIDTH-1:0]  header_bus,
      output reg                             headers_valid,

      // --- Register interface
      input                                 reg_req_in,
      input                                 reg_ack_in,
      input                                 reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]      reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]     reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]        reg_src_in,

      output reg                            reg_req_out,
      output reg                            reg_ack_out,
      output reg                            reg_rd_wr_L_out,
      output reg [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
      output reg [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
      output reg [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,

      // --- Misc
      input                                  reset,
      input                                  clk
   );

   function integer ceildiv;
      input integer num;
      input integer divisor;
      begin
         if (num <= divisor)
            ceildiv = 1;
         else begin
            ceildiv = num / divisor;
            if (ceildiv * divisor < num)
               ceildiv = ceildiv + 1;
         end
      end
   endfunction // ceildiv

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // -------------------------Module Parameters----------------------------//
   // State machine
   localparam  RD_INGRESS_PORT      = 1,
               RD_DLDST_DLSRCH      = 2,
               RD_DLSRCL_DLTYPE_TOS = 3,
               RD_NWPROTO           = 4,
               RD_NWSRC_NWDSTH      = 5,
               RD_NWDSTL_TX         = 6,
               WAIT_EOP             = 0;

   // Register parameters for register requests
   localparam NUM_REGS_USED = ceildiv(`OF_HEADER_REG_WIDTH, `CPCI_NF2_DATA_WIDTH);
   localparam ADDR_WIDTH = log2(NUM_REGS_USED);

   // -------------------------Wires and Registers--------------------------//
   reg [3:0]      rd_state;
   reg            rd_is_ip, rd_is_tp, rd_is_icmp;
   reg            rd_is_ipfrag;
   reg [3:0]      rd_hdr_len;


   // Register wires and registers for reads
   wire [ADDR_WIDTH-1:0]                                 addr;
   wire [`HDR_REG_ADDR_WIDTH - 1:0]                      reg_addr;
   wire [`UDP_REG_ADDR_WIDTH-`HDR_REG_ADDR_WIDTH - 1:0]  tag_addr;

   wire                                               addr_good;
   wire                                               tag_hit;

   reg [`CPCI_NF2_DATA_WIDTH-1:0]                     reg_data;
   reg [`OF_HEADER_REG_WIDTH-1:0]                     last_header;


   // -------------------------Module Logic---------------------------------//

   // Register assignments
   assign addr = reg_addr_in[ADDR_WIDTH-1:0];
   assign reg_addr = reg_addr_in[`HDR_REG_ADDR_WIDTH-1:0];
   assign tag_addr = reg_addr_in[`UDP_REG_ADDR_WIDTH - 1:`HDR_REG_ADDR_WIDTH];

   assign addr_good = reg_addr[`HDR_REG_ADDR_WIDTH-1:ADDR_WIDTH] == 'h0 &&
      addr < NUM_REGS_USED;
   assign tag_hit = tag_addr == `HDR_BLOCK_ADDR;
   // end register assignments

   // Register I/O Async block
   always @(*) begin
      // Defaults
      if (reset) begin
         reg_data = 'h0;
      end
      else begin
         if (addr == NUM_REGS_USED - 1) begin
            // 24 0s, 8 signifigant bits
            reg_data = {{(`OF_HEADER_REG_WIDTH - (`OF_HEADER_REG_WIDTH % `CPCI_NF2_DATA_WIDTH)){1'b0}},
               {last_header[addr * `CPCI_NF2_DATA_WIDTH +: `OF_HEADER_REG_WIDTH % `CPCI_NF2_DATA_WIDTH]}};
         end
         else begin
            reg_data = last_header[ addr * `CPCI_NF2_DATA_WIDTH +: `CPCI_NF2_DATA_WIDTH];
         end
      end
   end
   // end Register I/O Async block

   // Register I/O synchronous block
   // don't worry about this too much
   // handles ack, passing of data
   always @(posedge clk) begin
      // Never modify the address/src
      reg_rd_wr_L_out <= reg_rd_wr_L_in;
      reg_addr_out <= reg_addr_in;
      reg_src_out <= reg_src_in;

      if( reset ) begin
         reg_req_out <= 1'b0;
         reg_ack_out <= 1'b0;
         reg_data_out <= 'h0;
      end
      else begin
         if(reg_req_in && tag_hit) begin
            if(addr_good) begin
               reg_data_out <= reg_data;
            end
            else begin
               // Its our block, but we don't have the specific address
               reg_data_out <= 32'hdead_beef;
            end

            // requests complete after one cycle
            reg_ack_out <= 1'b1;
         end
         else begin
            reg_ack_out <= reg_ack_in;
            reg_data_out <= reg_data_in;
         end
         reg_req_out <= reg_req_in;
      end // else: !if( reset )
   end // always @ (posedge clk)


   // The following state machine parses the headers off a non-vlan IPv4
   // packet and stores them into the header bus, which is the interface
   // between this module and the lookup tables.
   always @(posedge clk) begin
      if(reset) begin
         rd_state <= RD_INGRESS_PORT;
         headers_valid <= 0;
         header_bus <= 0;
         rd_is_tp <= 0;
         rd_is_icmp <= 0;
         rd_is_ipfrag <= 0;
         rd_is_ip <= 0;
      end
      else begin
         if (in_wr) begin
            case (rd_state)
               RD_INGRESS_PORT: begin
                  if (in_ctrl == `IO_QUEUE_STAGE_NUM) begin
                     header_bus[`OF_IN_PORT + `OF_IN_PORT_POS - 1 : `OF_IN_PORT_POS] <= in_data[31:16];
                     rd_state <= RD_DLDST_DLSRCH;
                  end
               end
               RD_DLDST_DLSRCH: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_DL_DST + `OF_DL_DST_POS - 1 : `OF_DL_DST_POS] <= in_data[63:16];
                     header_bus[`OF_DL_SRC_POS + `OF_DL_SRC - 1: `OF_DL_SRC_POS + `OF_DL_SRC - 16] <= in_data[15:0];
                     rd_state <= RD_DLSRCL_DLTYPE_TOS;
                  end
               end
               RD_DLSRCL_DLTYPE_TOS: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_DL_SRC + `OF_DL_SRC_POS - 17 : `OF_DL_SRC_POS] <= in_data[63:32];
                     header_bus[`OF_DL_TYPE + `OF_DL_TYPE_POS - 1 : `OF_DL_TYPE_POS ] <= in_data[31:16];
                     // If Ethertype is IP
                     if (in_data[31:16] == 16'h0800) begin
                        header_bus[`OF_NW_TOS + `OF_NW_TOS_POS - 1 : `OF_NW_TOS_POS ] <= in_data[7:0];
                        rd_hdr_len <= in_data[11:8];
                        rd_is_ip <= 1;
                        rd_state <= RD_NWPROTO;
                     end
                     else begin
                        headers_valid <= 1;
                        rd_state <= WAIT_EOP;
                     end
                  end
               end
               RD_NWPROTO: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_NW_PROTO + `OF_NW_PROTO_POS - 1 : `OF_NW_PROTO_POS ] <= in_data[7:0];
                     // IP Fragmentation not supported
                     if (in_data[29] != 0 || in_data[28:16] != 13'h0000) begin
                        rd_is_ipfrag <= 1;
                     end
                     if (in_data[7:0] == 8'h06 || in_data[7:0] == 8'h11) begin
                        rd_is_tp <= 1;
                     end
                     else if (in_data[7:0] == 8'h01) begin
                        rd_is_icmp <= 1;
                     end
                     rd_state <= RD_NWSRC_NWDSTH;
                  end
               end
               RD_NWSRC_NWDSTH: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_NW_SRC + `OF_NW_SRC_POS - 1 : `OF_NW_SRC_POS ] <= in_data[47:16];
                     header_bus[`OF_NW_DST_POS + `OF_NW_DST - 1:`OF_NW_DST_POS + `OF_NW_DST - 16] <= in_data[15:0];
                     rd_state <= RD_NWDSTL_TX;
                  end
               end

               RD_NWDSTL_TX: begin
                  // This state is a little confusing  first, we parse the low
                  // data of the network destination address, then we go on to
                  // check if its a fragment.  If so, ignore transport.
                  // following that check, we parse the transport fields,
                  // which are dependant upon the IP header length, so we
                  // count down using the register from a previous state that
                  // read in the ip header length

                  if (rd_is_ip) begin
                     // Read only once
                     header_bus[`OF_NW_DST + `OF_NW_DST_POS - 17 : `OF_NW_DST_POS] <= in_data[63:48];
                     rd_is_ip <= 0;
                  end

                  if (rd_is_ipfrag) begin
                     headers_valid <= 1;
                     rd_state <= WAIT_EOP;
                  end 
                  else begin // else not ip frag

                     if (rd_hdr_len < 5) begin // This happens when tcp/udp src/dst get separated
                        header_bus[`OF_TP_DST + `OF_TP_DST_POS - 1 : `OF_TP_DST_POS] <= in_data[63:48];
                        headers_valid <= 1;
                        if ( in_ctrl != 0 ) begin
                           rd_state <= RD_INGRESS_PORT;
                        end else begin
                           rd_state <= WAIT_EOP;
                        end
                     end // hdr_len == 4

                     else if (rd_hdr_len == 5) begin
                        if (rd_is_icmp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS - 1 : `OF_TP_SRC_POS] <= in_data[47:40];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS - 1 : `OF_TP_DST_POS] <= in_data[39:32];
                        end else if (rd_is_tp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS - 1 : `OF_TP_SRC_POS] <= in_data[47:32];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS - 1 : `OF_TP_DST_POS] <= in_data[31:16];
                        end
                        headers_valid <= 1;
                        if ( in_ctrl != 0 ) begin
                           rd_state <= RD_INGRESS_PORT;
                        end else begin
                           rd_state <= WAIT_EOP;
                        end
                     end // hdr_len == 5
                     
                     else if (rd_hdr_len == 6) begin
                        if (rd_is_icmp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS - 1 : `OF_TP_SRC_POS] <= in_data[15:8];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS - 1 : `OF_TP_DST_POS] <= in_data[7:0];
                           headers_valid <= 1;
                           rd_state <= WAIT_EOP;
                        end else if (rd_is_tp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS - 1 : `OF_TP_SRC_POS] <= in_data[15:0];
                           rd_hdr_len <= rd_hdr_len - 2;
                           rd_state <= RD_NWDSTL_TX;
                        end
                     end // hdr_len == 6
                     
                     else begin // IP Header Len > 6 wait 
                        rd_hdr_len <= rd_hdr_len - 2;
                        rd_state <= RD_NWDSTL_TX;
                     end
                  end
               end

               WAIT_EOP: begin
                  // End of packet reached, reset headers
                  if (in_ctrl != 0) begin
                     headers_valid <= 0;
                     last_header <= header_bus;
                     header_bus <= 0;
                     rd_is_tp <= 0;
                     rd_is_icmp <= 0;
                     rd_is_ipfrag <= 0;
                     rd_is_ip <= 0;
                     rd_state <= RD_INGRESS_PORT;
                  end
               end
            endcase
         end
      end
   end

endmodule // myprocessor
