------------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      bpm_pkg.vhd - 
--
--      Copyright(c) Stanford Linear Accelerator Center 2000
--
--      Author: Jeff Olsen
--      Created on: 08/23/05 
--      Last change: JO 12/13/2007 5:24:29 PM
--
-- 
-- Created by Jeff Olsen 02/16/05
--
--  Filename: bpm_pkg.vhd
--
--  Function:
--  Package declarations for LCLS BPM

--
--  Modifications:
-- Version 2
-- 11/16/06 jjo
-- Changed long reset to a Retriggerable one shot
--      limiter.vhd
-- 11/17/06 jjo
-- Changed timing so that C3 and C4 is on 2us after C1


-- 12/15/06
-- Upgraded the QSPI Interface

--01/18/07 jjo
-- Version 3
-- Completely changed sequencer
-- Added 5 registers to control sequence
-- Trig2AMP => Time from trigger to AMP On
-- AMP2RF1 => Time from AMP on to first RF pulse
-- RF12RF2 => Time from first RF pulse to second RF pulse
-- RFWidth => Width of RF Pulse
-- OffTime => Time from RF pulse to end of Enable

--03/05/07 jjo
-- Version 4
-- Added trigger handshake using Qspi CS2 and CS3
-- Clocked Cal Sequencer at 60Mhz * 2
-- Sync'd triggers to 60Mhz * 2

--08/18/20 jjo
--
-- added not CS to the reset of the SPI state-machine
-- 

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;

package bpm is

  constant version          : std_logic_vector(6 downto 0)  := "0110000";  -- 0x30
--
  constant CSR_Addr         : std_logic_vector(7 downto 0)  := x"00";
  constant CAL_Addr         : std_logic_vector(7 downto 0)  := x"01";
  constant ATT1_Addr        : std_logic_vector(7 downto 0)  := x"02";
  constant ATT2_Addr        : std_logic_vector(7 downto 0)  := x"03";
  constant LMT_Addr         : std_logic_vector(7 downto 0)  := x"04";
  constant VER_Addr         : std_logic_vector(7 downto 0)  := x"05";
  constant TRG_Addr         : std_logic_vector(7 downto 0)  := x"06";
-- 01/18/07 jjo
-- Added registers
  constant Trig2AMP_Addr    : std_logic_vector(7 downto 0)  := x"10";
  constant AMP2RF1_Addr     : std_logic_vector(7 downto 0)  := x"11";
  constant RF12RF2_Addr     : std_logic_vector(7 downto 0)  := x"12";
  constant RFWidth_Addr     : std_logic_vector(7 downto 0)  := x"13";
  constant OffTime_Addr     : std_logic_vector(7 downto 0)  := x"14";
--
  constant OscMode_Auto     : std_logic_vector(1 downto 0)  := "00";
  constant OscMode_On       : std_logic_vector(1 downto 0)  := "01";
  constant OscMode_Off      : std_logic_vector(1 downto 0)  := "10";
  constant OscMode_Unused   : std_logic_vector(1 downto 0)  := "11";
--
  constant BOOT_Addr        : std_logic_vector(7 downto 0)  := x"3E";
  constant JTAG_Addr        : std_logic_vector(7 downto 0)  := x"3F";
-- Clock always at 60mhz *2
-- Count is divided by 4 in Cal_Seq by
-- appending "00"
-- 1us = 30
--Constant Trig2AMP_Default     : std_logic_vector(7 downto 0) := x"1E";
  constant Trig2AMP_Default : std_logic_vector(7 downto 0)  := x"05";
-- 1.4ms = 144
  constant AMP2RF1_Default  : std_logic_vector(7 downto 0)  := x"90";
-- 2us = 60
  constant RF12RF2_Default  : std_logic_vector(7 downto 0)  := x"3C";
-- 300ns = 9
  constant RFWidth_Default  : std_logic_vector(7 downto 0)  := x"09";
-- 2us = 60
  constant OffTime_Default  : std_logic_vector(7 downto 0)  := x"3C";
--
  constant LMTR_Long_Delay  : std_logic_vector(15 downto 0) := x"012C";
  constant LMTR_Long_Width  : std_logic_vector(15 downto 0) := x"0002";
--
  constant LMTR_Short_Delay : std_logic_vector(15 downto 0) := x"0004";
  constant LMTR_Short_Width : std_logic_vector(15 downto 0) := x"0002";
--
  constant OscOn_Tick       : std_logic_vector(19 downto 0) := x"004B0";
--
  constant RedMode          : std_logic_vector(1 downto 0)  := "00";
  constant GreenMode        : std_logic_vector(1 downto 0)  := "01";
  constant BothMode         : std_logic_vector(1 downto 0)  := "10";

  component bpm_x
    port (
      Sys_Clock     : in    std_logic;
      Local_Clock   : in    std_logic;
      Reset         : in    std_logic;
      Cal_Init      : in    std_logic;
-- QSPI
      n_QSPI_CS     : in    std_logic_vector(3 downto 0);
      Qspi_CLK      : in    std_logic;
      Qspi_DOut     : inout std_logic;
      Qspi_DIn      : in    std_logic;
      -- RS232
      n_RS232_TX    : out   std_logic;
      n_RS232_RX    : in    std_logic;
      -- Reboot
      PROG_TDI      : out   std_logic;  -- to PROM TDI
      PROG_TDO      : in    std_logic;  -- from PROM TDO
      PROG_TMS      : out   std_logic;
      PROG_TCK      : out   std_logic;
      SEL_SEC       : out   std_logic;
      SEL_CLK       : out   std_logic;
      Reboot        : out   std_logic;
-- Calibrator
      CAL_ATT       : out   std_logic_vector(5 downto 1);
      CAL_SW        : out   std_logic_vector(4 downto 1);
      VAPC          : out   std_logic;
      OSC_On        : out   std_logic;
-- Limiter
      LMTR_Pulse    : in    std_logic;
      LMTR_Long_Rst : out   std_logic;
      LMTR_Fast_Rst : out   std_logic;
-- Attenuator controls
      ATT_Cntl4B    : out   std_logic_vector(4 downto 1);
      ATT_Cntl4A    : out   std_logic_vector(4 downto 1);
      ATT_Cntl3B    : out   std_logic_vector(4 downto 1);
      ATT_Cntl3A    : out   std_logic_vector(4 downto 1);
      ATT_Cntl2B    : out   std_logic_vector(5 downto 1);
      ATT_Cntl2A    : out   std_logic_vector(5 downto 1);
      ATT_Cntl1B    : out   std_logic_vector(5 downto 1);
      ATT_Cntl1A    : out   std_logic_vector(5 downto 1);
      Clk20MhzOut   : out   std_logic

      );

  end component;  --bpm_x;


  component prog_strobe is
    port (
      Clock     : in  std_logic;
      Reset     : in  std_logic;
      TriggerIn : in  std_logic;
      Delay     : in  std_logic_vector(15 downto 0);
      Width     : in  std_logic_vector(15 downto 0);
      Pulse     : out std_logic
      );
  end component;  --prog_strobe ;

  component qspi is
    port (
      Clock      : in  std_logic;
      Reset      : in  std_logic;
      Din        : in  std_logic;
      Dout       : out std_logic;
      Cs         : in  std_logic;
      Write_Strb : out std_logic;
      DataOut    : out std_logic_vector(7 downto 0);
      Address    : out std_logic_vector(7 downto 0);
      En         : out std_logic;
      DataIn     : in  std_logic_vector(7 downto 0)
      );
  end component;  --qspi 


  component bpm_reg is
    port (
      Clock      : in  std_logic;
      Reset      : in  std_logic;
      Address    : in  std_logic_vector(7 downto 0);
      Write_Strb : in  std_logic;
      DataIn     : in  std_logic_vector(7 downto 0);
      DataOut    : out std_logic_vector(7 downto 0);

-- CSR 0
      ModeSel    : out std_logic_vector(1 downto 0);
-- CAL
      CalATT     : out std_logic_vector(4 downto 0);
      OscMode    : out std_logic_vector(1 downto 0);
-- ATT
      ATT1       : out std_logic_vector(3 downto 0);
      ATT2       : out std_logic_vector(4 downto 0);
-- LMT
      Trip       : in  std_logic;
-- Cal Sequencer
      TRIG2AMP   : out std_logic_vector(7 downto 0);
      AMP2RF1    : out std_logic_vector(7 downto 0);
      RF12RF2    : out std_logic_vector(7 downto 0);
      RFWIDTH    : out std_logic_vector(7 downto 0);
      OFFTIME    : out std_logic_vector(7 downto 0);
-- JTAG
      TMS        : out std_logic;
      TCK        : out std_logic;
      TDI        : out std_logic;
      TDO        : in  std_logic;
      Sel_Sec    : out std_logic;
      Sel_Clk    : out std_logic;
      Reboot     : out std_logic;
      Lmtr_Long  : out std_logic;
      Lmtr_Short : out std_logic

      );

  end component;

  component limiter is
    port (
      Clock         : in  std_logic;
      Reset         : in  std_logic;
      LMT_Pulse     : in  std_logic;
      LMT_Short_Rst : out std_logic;
      LMT_Long_Rst  : out std_logic
      );
  end component;  --limiter

  component cal_seq is
    port (
      Clock       : in  std_logic;
      Reset       : in  std_logic;
      Sys_Trigger : in  std_logic;
      ModeSel     : in  std_logic_vector(1 downto 0);
      OscMode     : in  std_logic_vector(1 downto 0);
      TRIG2AMP    : in  std_logic_vector(7 downto 0);
      AMP2RF1     : in  std_logic_vector(7 downto 0);
      RF12RF2     : in  std_logic_vector(7 downto 0);
      RFWIDTH     : in  std_logic_vector(7 downto 0);
      OFFTIME     : in  std_logic_vector(7 downto 0);
      CAL_SW      : out std_logic_vector(6 downto 1);
      C2          : out std_logic;
      C4          : out std_logic;
      VAPC        : out std_logic;
      OscOn       : out std_logic
      );
  end component;  --cal_seq


  component rs232_rx is
    port (
      RxCLK    : in  std_logic;
      Reset    : in  std_logic;
      RxDin    : in  std_logic;
      RxData   : out std_logic_vector(7 downto 0);
      RxDone   : out std_logic;
      RxParity : out std_logic
      );
  end component;  --rs232_rx;



  component rs232_tx is
    port (
      TxCLK  : in  std_logic;
      Reset  : in  std_logic;
      Xmit   : in  std_logic;
      Data   : in  std_logic_vector(7 downto 0);
      TxDone : out std_logic;
      TxOut  : out std_logic
      );
  end component;  --rs232_tx;

  component transmit is

    port (
      CLK     : in  std_logic;
      Reset   : in  std_logic;
      NewData : in  std_logic;
      DataIn  : in  std_logic_vector(7 downto 0);
      Addr    : in  std_logic_vector(7 downto 0);
      DataOut : out std_logic_vector(7 downto 0);
      TxDone  : in  std_logic;
      Xmit    : out std_logic;
      EnDout  : out std_logic
      );
  end component;  -- transmit;

  component receive is
    port (
      CLK    : in  std_logic;
      Reset  : in  std_logic;
      Parity : in  std_logic;
      DAV    : in  std_logic;
      DataIn : in  std_logic_vector(7 downto 0);
      Valid  : out std_logic;
      Addr   : out std_logic_vector(7 downto 0);
      Data   : out std_logic_vector(7 downto 0);
      En     : out std_logic
      );
  end component;  --receive;

  component rs232intf is
    port (
      Clk       : in  std_logic;
      Reset     : in  std_logic;
-- Receiver
      Rx        : in  std_logic;
      RxDataOut : out std_logic_vector(7 downto 0);
      RxAddrOut : out std_logic_vector(7 downto 0);
      WriteStrb : out std_logic;

-- Transmitter
      TxDataIn : in  std_logic_vector(7 downto 0);
      Tx       : out std_logic;
      En       : out std_logic
      );
  end component;  --rs232intf;


  component regseq is
    port (
      CLK        : in  std_logic;
      Reset      : in  std_logic;
--
      rs232Wr    : in  std_logic;
      rs232DIn   : in  std_logic_vector(7 downto 0);
      rs232AIn   : in  std_logic_vector(7 downto 0);
      rs232En    : in  std_logic;
--
      qspiWr     : in  std_logic;
      qspiDIn    : in  std_logic_vector(7 downto 0);
      qspiAIn    : in  std_logic_vector(7 downto 0);
      qspiEn     : in  std_logic;
--
      Write_Strb : out std_logic;
      DataOut    : out std_logic_vector(7 downto 0);
      AddrOut    : out std_logic_vector(7 downto 0)

      );
  end component;  --regseq;

  component BUFG is
    port (I : in  std_logic;
          O : out std_logic);
  end component;

  component clkdiv3 is
    port (
      CLKIN_IN   : in  std_logic;
      RST_IN     : in  std_logic;
      CLKDV_OUT  : out std_logic;
      CLK0_OUT   : out std_logic;
      LOCKED_OUT : out std_logic);
  end component;  --clkdiv3;

  component clkdiv2 is
    port (
      CLKIN_IN   : in  std_logic;
      RST_IN     : in  std_logic;
      CLKDV_OUT  : out std_logic;
      CLK0_OUT   : out std_logic;
      LOCKED_OUT : out std_logic);
  end component;  --clkdiv2;

  component oneshot
    port (
      Clock    : in  std_logic;
      Reset    : in  std_logic;
      Start    : in  std_logic;
      RetrigEn : in  std_logic;
      Level    : in  std_logic;
      OS_Time  : in  std_logic_vector(15 downto 0);
      OS_Out   : out std_logic
      );
  end component;  --oneshot;

  component clk2x
    port (
      CLKIN_IN        : in  std_logic;
      RST_IN          : in  std_logic;
      CLKIN_IBUFG_OUT : out std_logic;
      CLK0_OUT        : out std_logic;
      CLK2X_OUT       : out std_logic;
      LOCKED_OUT      : out std_logic
      );
  end component;  --clk2x

  component trigcon
    port (
      Clock       : in  std_logic;
      Reset       : in  std_logic;
      Sw_Trigger  : in  std_logic;
      Cal_Init    : in  std_logic;
      Sys_Trigger : out std_logic
      );

  end component;  --trigcon

  component trighandshake
    port (
      Clock       : in  std_logic;
      Reset       : in  std_logic;
      Sys_Trigger : in  std_logic;
      Triggered   : out std_logic;
      Trig_reset  : in  std_logic
      );
  end component;  --trighandshake

end bpm;

