`timescale 1ns/1ps

module passthrough
   #(parameter DATA_WIDTH = 64,
   parameter CTRL_WIDTH = DATA_WIDTH/8
   )
   (// --- Interface to the previous stage
      input  [DATA_WIDTH-1:0]                in_data,
      input  [CTRL_WIDTH-1:0]                in_ctrl,
      input                                  in_wr,
      output                                 in_rdy,

      // --- Interface to the next stage
      output reg [`OF_HEADER_REG_WIDTH-1:0]  header_bus,
      output reg                             headers_valid;

      // --- Misc
      input                                  reset,
      input                                  clk
   );

   localparam  RD_INGRESS_PORT      = 1,
               RD_DLDST_DLSRCH      = 2,
               RD_DLSRCL_DLTYPE_TOS = 3,
               RD_NWPROTO           = 4,
               RD_NWSRC_NWDSTH      = 5,
               RD_NWDSTL_TX         = 6,
               RD_TX_MORE           = 7,
               WAIT_EOP             = 0;

   reg [3:0]      rd_state;
   reg            rd_is_ip, rd_is_xdp, rd_is_icmp;
   reg            rd_is_ipfrag;
   reg [3:0]      rd_hdr_len;

   always @(posedge clk) begin
      if(reset) begin
         rd_state <= RD_INGRESS_PORT;
         headers_valid <= 0;
         header_bus <= 0;
      end
      else begin
         if (in_wr) begin
            case (rd_state)
               RD_INGRESS_PORT: begin
                  if (in_ctrl == `IO_QUEUE_STAGE_NUM) begin
                     header_bus[`OF_IN_PORT + `OF_IN_PORT_POS:`OF_IN_PORT_POS] <= in_data[31:16];
                     rd_state <= RD_DLDST_DLSRCH;
                  end
               end
               RD_DLDST_DLSRCH: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_DL_DST + `OF_DL_DST_POS:`OF_DL_DST_POS] <= in_data[63:16];
                     header_bus[`OF_DL_SRC_POS + 15:`OF_DL_SRC_POS] <= in_data[15:0];
                     rd_state <= RD_DLSRCL_DLTYPE_TOS;
                  end
               end
               RD_DLSRCL_DLTYPE_TOS: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_DL_SRC + `OF_DL_SRC_POS :`OF_DL_SRC_POS + 16 ] <= in_data[63:32];
                     header_bus[`OF_DL_TYPE + `OF_DL_TYPE_POS :`OF_DL_TYPE_POS ] <= in_data[31:16];
                     // If Ethertype is IP
                     if (in_data[31:16] == 16'h0800) begin
                        header_bus[`OF_NW_TOS + `OF_NW_TOS_POS :`OF_NW_TOS_POS ] <= in_data[7:0];
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
                     header_bus[`OF_NW_PROTO + `OF_NW_PROTO_POS :`OF_NW_PROTO_POS ] <= in_data[7:0];
                     // IP Fragmentation not supported
                     if (in_data[15] != in_data[13] or in_data[12:0] != 13'h0000) begin
                        rd_is_ipfrag <= 1;
                     end
                     rd_state <= RD_NWSRC_NWDSTH;
                  end
               end
               RD_NWSRC_NWDSTH: begin
                  if (in_ctrl == 0) begin
                     header_bus[`OF_NW_SRC + `OF_NW_SRC_POS :`OF_NW_SRC_POS ] <= in_data[47:16];
                     header_bus[`OF_NW_DST_POS+ 15:`OF_NW_DST_POS ] <= in_data[15:0];
                     rd_state <= RD_NWDSTL_TX;
                  end
               end
               RD_NWDSTL_TX: begin
                  header_bus[`OF_NW_DST + `OF_NW_DST_POS:`OF_NW_DST_POS + 16] <= in_data[63:48];
                  if (rd_is_ipfrag) begin
                     headers_valid <= 1;
                     rd_state <= WAIT_EOP;
                  end else begin
                     if (rd_hdr_len < 6) begin
                        if (rd_is_icmp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[47:40];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[39:32];
                        end else if (rd_is_xdp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[47:32];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[31:16];
                        end
                        headers_valid <= 1;
                        if ( in_ctrl != 0 ) begin
                           rd_state <= RD_INGRESS_PORT;
                        end else begin
                           rd_state <= WAIT_EOP;
                        end
                     end else if (rd_hdr_len == 6) begin
                        if (rd_is_icmp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[15:8];
                           header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[7:0];
                           headers_valid <= 1;
                           rd_state <= WAIT_EOP;
                        end else if (rd_is_xdp) begin
                           header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[15:0];
                           rd_hdr_len <= rd_hdr_len - 2;
                           rd_state <= RD_TX_MORE;
                        end
                     end else begin // IP Header Len > 6
                        rd_hdr_len <= rd_hdr_len - 2;
                        rd_state <= RD_TX_MORE;
                     end
                  end
               end
               RD_TX_MORE: begin
                  if (rd_hdr_len < 6) begin
                     if (rd_is_icmp) begin
                        header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[47:40];
                        header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[39:32];
                     end else if (rd_is_xdp) begin
                        header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[47:32];
                        header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[31:16];
                     end
                     headers_valid <= 1;
                     if ( in_ctrl != 0 ) begin
                        rd_state <= RD_INGRESS_PORT;
                     end else begin
                        rd_state <= WAIT_EOP;
                     end
                  end else if (rd_hdr_len == 6) begin
                     if (rd_is_icmp) begin
                        header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[15:8];
                        header_bus[`OF_TP_DST + `OF_TP_DST_POS :`OF_TP_DST_POS] <= in_data[7:0];
                        headers_valid <= 1;
                        rd_state <= WAIT_EOP;
                     end else if (rd_is_xdp) begin
                        header_bus[`OF_TP_SRC + `OF_TP_SRC_POS :`OF_TP_SRC_POS] <= in_data[15:0];
                        rd_hdr_len <= rd_hdr_len - 2;
                        rd_state <= RD_TX_MORE;
                     end
                  end else begin // IP Header Len > 6
                     rd_hdr_len <= rd_hdr_len - 2;
                     rd_state <= RD_TX_MORE;
                  end
               end
               WAIT_EOP: begin
                  if (in_ctrl != 0) begin
                     headers_valid <= 0;
                     header_bus <= 0;
                     rd_state <= PRE_READ_HDR;
                  end
               end
            endcase
         end
      end
   end

endmodule // myprocessor
