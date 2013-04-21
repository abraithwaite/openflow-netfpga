// Replace YOUR with the prefix defined in the xml file

   // --- Helper functions
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
   // --- /helper functions

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

   // Parameters used for registers
   localparam NUM_REGS_USED = ??;
   localparam ADDR_WIDTH = ??;

   //Wires/registers used for registers
   wire [ADDR_WIDTH-1:0]                                 addr;
   wire [`YOUR_REG_ADDR_WIDTH - 1:0]                      reg_addr;
   wire [`UDP_REG_ADDR_WIDTH-`YOUR_REG_ADDR_WIDTH - 1:0]  tag_addr;

   wire                                               addr_good;
   wire                                               tag_hit;

   reg [`CPCI_NF2_DATA_WIDTH-1:0]                     reg_data;
   reg [`CPCI_NF2_DATA_WIDTH-1:0]                     packet_count;
   reg [`CPCI_NF2_DATA_WIDTH-1:0]                     wr_packet_count;
   reg                                                packet_inc;
   reg                                                wr_reg;


   // Register assignments
   assign addr = reg_addr_in[ADDR_WIDTH-1:0];
   assign reg_addr = reg_addr_in[`YOUR_REG_ADDR_WIDTH-1:0];
   assign tag_addr = reg_addr_in[`UDP_REG_ADDR_WIDTH - 1:`YOUR_REG_ADDR_WIDTH];

   assign addr_good = reg_addr[`YOUR_REG_ADDR_WIDTH-1:ADDR_WIDTH] == 'h0 &&
      addr < NUM_REGS_USED;
   assign tag_hit = tag_addr == `YOUR_BLOCK_ADDR;
   // end register assignments

   // The following is some boilerplate logic for registers
   // It doesn't account for register writes very well
   // if theres a write wr_reg will be set, and the always
   // block that is responsible for the write will have to update
   // the register containing the relevant data
   // Register I/O Async block
   always @(*) begin
      // Defaults
      wr_reg = 0;
      wr_packet_count = 0;
      if (reset) begin
         reg_data = 'h0;
      end
      else begin
         // If its a write to our block
         if (!reg_rd_wr_L_in && reg_req_in && tag_hit) begin
            wr_reg = 1;
            case (addr)
               `YOUR_REGISTER_DEFINE: begin
                  wr_some_register = reg_data_in;
               end
            endcase
         end
         // It's a read, simply assign the out_data to the data requested
         else begin
            case (addr)
               `YOUR_REGISTER_DEFINE:        reg_data = some_register;
            endcase // case (reg_cnt)
         end
      end
   end

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
   // end Registers
