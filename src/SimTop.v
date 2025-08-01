`timescale 1ns/100ps
`default_nettype none

module top_sim;
  reg clk;
  always #12 clk = !clk;

  reg resetq = 0;

  wire oled_vdd;
  wire oled_res;
  wire oled_sclk;
  wire oled_vbat;
  wire oled_sdin;
  wire oled_dc;
  wire oled_debug;

  TestOled inst (
    .out_oled_vdd(oled_vdd),
    .out_oled_reset(oled_res),
    .out_oled_clk(oled_sclk),
    .out_oled_vbat(oled_vbat),
    .out_oled_dout(oled_sdin),
    .out_oled_isData(oled_dc),
    .out_oled_debug(oled_debug),
    .clock(clk),
    .reset(resetq)
  );

  //TestSdram top(
  //  .clock(clk),
  //  .reset(resetq),
  //  .out_sdram_din_0(sdram_din),
  //  .out_sdram_din_en(1),
  //  .out_sdram_dout(sdram_dout),
  //  .out_sdram_den(sdram_den),
  //  .out_sdram_csn(sdram_csn),
  //  .out_sdram_wen(sdram_wen),
  //  .out_sdram_rasn(sdram_rasn),
  //  .out_sdram_casn(sdram_casn),
  //  .out_sdram_a(sdram_a),
  //  .out_sdram_ba(sdram_ba),
  //  .out_sdram_dqm(sdram_dqm)
  //);

  //wire  sdram_csn;       // chip select
  //wire  sdram_clk;       // clock to SDRAM
  //wire  sdram_cke;       // clock enable to SDRAM
  //wire  sdram_rasn;      // SDRAM RAS
  //wire  sdram_casn;      // SDRAM CAS
  //wire  sdram_wen;       // SDRAM write-enable
  //wire [12:0] sdram_a;   // SDRAM address bus
  //wire  [1:0] sdram_ba;  // SDRAM bank-address
  //wire  [1:0] sdram_dqm; // byte select
  //wire [15:0] sdram_d;   // data

  //assign sdram_clk = ~clk;
  //wire [15:0] sdram_dout;
  //wire [15:0] sdram_din;
  //wire sdram_den;

  //assign sdram_din = sdram_d;
  //assign sdram_d = sdram_den ? sdram_dout : 16'bzzzz;

  //mt48lc16m16a2 memory(
  //  .Dq(sdram_d),
  //  .Addr(sdram_a),
  //  .Ba(sdram_ba),
  //  .Clk(sdram_clk),
  //  .Cke(sdram_cke),
  //  .Cs_n(sdram_csn),
  //  .Ras_n(sdram_rasn),
  //  .Cas_n(sdram_casn),
  //  .We_n(sdram_wen),
  //  .Dqm(sdram_dqm)
  //);

  integer i;
  initial begin
    $dumpfile("Verilog/top_sim.vcd");    // create a VCD waveform dump
    $dumpvars(0, top_sim); // dump variable changes in the testbench
    clk = 0;
    resetq = 0;

    @(negedge clk);
    resetq = 1;
    @(negedge clk);
    resetq = 0;

    for (i=0; i < 100000000; i = i + 1) begin
      @(negedge clk);
    end

    $finish;
  end

endmodule
