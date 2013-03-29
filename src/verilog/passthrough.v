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
        output reg [DATA_WIDTH-1:0]            out_data,
        output reg [CTRL_WIDTH-1:0]            out_ctrl,
        output reg                             out_wr,
        input                                  out_rdy,

        // --- Misc
        input                                  reset,
        input                                  clk
    );

    localparam  PRE_READ_HDR    = 1,
                PRE_WAIT_EOP    = 2;

    localparam  RX_QUEUE_HDR    = 8'hFF;

    localparam  PRO_WAIT        = 1,
                PRO_MODIFY_HDR  = 2,
                PRO_WRITE       = 4;

    localparam  PORT0           = 1,
                PORT1           = 4,
                PORT2           = 16,
                PORT3           = 64;

    wire [DATA_WIDTH-1:0] fifo_data_out;
    wire [CTRL_WIDTH-1:0] fifo_ctrl_out;

    reg [1:0]             pre_state;
    reg [15:0]            src_port;
    reg                   port_vld;

    reg [2:0]             pro_state;
    reg [2:0]             pro_state_nxt;
    reg                   fifo_rd_en;
    reg                   out_wr_nxt;
    reg [DATA_WIDTH-1:0]  out_data_nxt;
    reg [CTRL_WIDTH-1:0]  out_ctrl_nxt;

    fallthrough_small_fifo
    #(.WIDTH(CTRL_WIDTH+DATA_WIDTH), .MAX_DEPTH_BITS(3))
    input_fifo(
    .din           ({in_ctrl, in_data}),  // Data in
    .wr_en         (in_wr),             // Write enable
    .rd_en         (fifo_rd_en),    // Read the next word
    .dout          ({fifo_ctrl_out, fifo_data_out}),
    .full          (),
    .prog_full     (),
    .nearly_full   (fifo_nearly_full),
    .empty         (fifo_empty),
    .reset         (reset),
    .clk           (clk)
    );

    // -- Logic -- //
    assign in_rdy = !fifo_nearly_full;

    always @(posedge clk) begin
        if(reset) begin
            // Default states
            pre_state   <= PRE_READ_HDR;
            port_vld    <= 0;
            src_port    <= 0;
        end
        else begin
            case (pre_state)
                // Read headers as soon as we have the right one
                PRE_READ_HDR: begin
                    if (in_wr && in_ctrl == `IO_QUEUE_STAGE_NUM) begin
                        src_port  <= in_data[31:16];
                        port_vld <= 1;
                        pre_state <= PRE_WAIT_EOP;
                    end
                end

                PRE_WAIT_EOP: begin
                    if (in_wr && in_ctrl != 0) begin
                        port_vld <= 0;
                        pre_state <= PRE_READ_HDR;
                    end
                end
            endcase
        end
    end

    /* This block modifies the port and sends it to the output
    */
    always @(*) begin
        pro_state_nxt       = pro_state;
        fifo_rd_en          = 0;
        out_wr_nxt          = 0;
        out_data_nxt        = fifo_data_out;
        out_ctrl_nxt        = fifo_ctrl_out;
        case (pro_state)
            PRO_WAIT: begin
                if (port_vld) begin
                    pro_state_nxt = PRO_MODIFY_HDR;
                end
            end

            PRO_MODIFY_HDR: begin
                if (out_rdy && !fifo_empty) begin
                    fifo_rd_en  = 1;
                    out_wr_nxt  = 1;
                    case(src_port)
                        PORT0: begin
                            out_data_nxt[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = PORT1;
                        end
                        PORT1: begin
                            out_data_nxt[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = PORT0;
                        end
                        PORT2: begin
                            out_data_nxt[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = PORT3;
                        end
                        PORT3: begin
                            out_data_nxt[`IOQ_DST_PORT_POS+15:`IOQ_DST_PORT_POS] = PORT2;
                        end
                    endcase
                    pro_state_nxt = PRO_WRITE;
                end
            end

            PRO_WRITE: begin
                if (out_rdy && !fifo_empty) begin
                    // End of packet data marked by non-zero ctrl
                    if (fifo_ctrl_out != 0) begin
                        pro_state_nxt = PRO_WAIT;
                    end
                    fifo_rd_en      = 1;
                    out_wr_nxt      = 1;
                end
            end
        endcase
    end

    /* This is the block that actually writes the output and increments the
    * read from the input fifo and increments the state
    */
    always @(posedge clk) begin
        if (reset) begin
            pro_state        <= PRO_WAIT;
            out_wr           <= 0;
            out_data         <= 0;
            out_ctrl         <= 1;
        end
        else begin
            pro_state       <= pro_state_nxt;
            out_wr          <= out_wr_nxt;
            out_data        <= out_data_nxt;
            out_ctrl        <= out_ctrl_nxt;
        end
    end


endmodule // myprocessor
