-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  bpm_x.vhd - 
--
--  Copyright(c) Stanford Linear Accelerator Center 2000
--
--  Author: JEFF OLSEN
--  Created on: 8/4/2006 11:03:32 AM
--  Last change: JO 12/13/2007 5:25:10 PM
--
-- Version 2
-- 11/17/06 jjo
-- Changed timing so that C3 and C4 is on 2 us after C1
-- Changed long reset to a Retriggerable one shot
--      limiter.vhd

library work;
use work.bpm.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity bpm_x is
  port (
    Sys_Clock        : in  std_logic;
    Local_Clock      : in  std_logic;
    Reset            : in  std_logic;
    Cal_Init         : in  std_logic;
--
    Triggered        : out std_logic;   -- Formerly CS3
    Trig_reset       : in  std_logic;   -- Formerly CS2
-- QSPI
    n_QSPI_CS        : in  std_logic_vector(1 downto 0);
    Qspi_CLK         : in  std_logic;
    Qspi_DOut        : out std_logic;
    Qspi_DIn         : in  std_logic;
-- RS232
    n_RS232_TX       : out std_logic;
    n_RS232_RX       : in  std_logic;
-- Reboot
    PROG_TDI         : out std_logic;   -- to PROM TDI
    PROG_TDO         : in  std_logic;   -- from PROM TDO
    PROG_TMS         : out std_logic;
    PROG_TCK         : out std_logic;
    SEL_SEC          : out std_logic;
    SEL_CLK          : out std_logic;
    n_Reboot         : out std_logic;
-- Calibrator
    CAL_ATT          : out std_logic_vector(5 downto 1);
    CAL_SW           : out std_logic_vector(6 downto 1);
    VAPC             : out std_logic;
    Osc_On           : out std_logic;
-- Limiter
    LMTR_Pulse       : in  std_logic;
    n_LMTR_Long_Rst  : out std_logic;
    n_LMTR_Short_Rst : out std_logic;
-- Attenuator controls
    ATT_Cntl4B       : out std_logic_vector(4 downto 1);
    ATT_Cntl4A       : out std_logic_vector(4 downto 1);
    ATT_Cntl3B       : out std_logic_vector(4 downto 1);
    ATT_Cntl3A       : out std_logic_vector(4 downto 1);
    ATT_Cntl2B       : out std_logic_vector(5 downto 1);
    ATT_Cntl2A       : out std_logic_vector(5 downto 1);
    ATT_Cntl1B       : out std_logic_vector(5 downto 1);
    ATT_Cntl1A       : out std_logic_vector(5 downto 1)
    );
end bpm_x;


architecture Behaviour of bpm_x is

  signal QCs              : std_logic;
  signal QEn              : std_logic;
  signal iQDout           : std_logic;
  signal QDin             : std_logic;
  signal QWrStrb          : std_logic;
  signal QAddrOut         : std_logic_vector(7 downto 0);
  signal QDataOut         : std_logic_vector(7 downto 0);
--
  signal RegAddress       : std_logic_vector(7 downto 0);
  signal Write_Strb       : std_logic;
  signal RegDataIn        : std_logic_vector(7 downto 0);
  signal RegDataOut       : std_logic_vector(7 downto 0);
  signal ModeSel          : std_logic_vector(1 downto 0);
--
  signal ATT4             : std_logic_vector(4 downto 1);
  signal ATT3             : std_logic_vector(4 downto 1);
  signal ATT2             : std_logic_vector(5 downto 1);
  signal ATT1             : std_logic_vector(5 downto 1);
--
  signal iATT1            : std_logic_vector(4 downto 1);
  signal iATT2            : std_logic_vector(5 downto 1);
--
  signal Clk20Mhz         : std_logic;
  signal Clk30Mhz         : std_logic;
  signal Clk60Mhz         : std_logic;
  signal Clk120Mhz        : std_logic;
--
  signal rs232WrStrb      : std_logic;
  signal RxDataOut        : std_logic_vector(7 downto 0);
  signal RxAddrOut        : std_logic_vector(7 downto 0);
  signal rs232En          : std_logic;
  signal RS232_Rx         : std_logic;
  signal RS232_Tx         : std_logic;
  signal Fast_Clock       : std_logic;
--
  signal iCAL_ATT         : std_logic_vector(5 downto 1);
  signal iLMTR_Long_Rst   : std_logic;
  signal iLMTR_Short_Rst  : std_logic;
  signal Force_Lmtr_Long  : std_logic;
  signal Force_Lmtr_Short : std_logic;
  signal Reboot           : std_logic;
--
  signal TRIG2AMP         : std_logic_vector(7 downto 0);
  signal AMP2RF1          : std_logic_vector(7 downto 0);
  signal RF12RF2          : std_logic_vector(7 downto 0);
  signal RFWIDTH          : std_logic_vector(7 downto 0);
  signal OFFTIME          : std_logic_vector(7 downto 0);
  signal LMTR_Long_Rst    : std_logic;
  signal LMTR_Short_Rst   : std_logic;
  signal Sys_Trigger      : std_logic;
  signal Sw_Trigger       : std_logic;
--
  signal RS232_Trig       : std_logic;
  signal QSPI_Trig        : std_logic;
--
  signal OscMode          : std_logic_vector(1 downto 0);
--
  signal Red              : std_logic;
  signal Green            : std_logic;

begin

  n_Reboot         <= not(Reboot);
--
  n_LMTR_Long_Rst  <= not(LMTR_Long_Rst);
  n_LMTR_Short_Rst <= not(LMTR_Short_Rst);
--
  LMTR_Long_Rst    <= (iLMTR_Long_Rst or Force_Lmtr_Long);
  LMTR_Short_Rst   <= (iLMTR_Short_Rst or Force_Lmtr_Short);
--
  QCs              <= not(n_QSPI_Cs(0));
--
--ATT_Cntl4B <= ATT2;
--ATT_Cntl4A <= ATT1;
--ATT_Cntl3B <= ATT2;
--ATT_Cntl3A <= ATT1;
--ATT_Cntl2B <= ATT2;
--ATT_Cntl2A <= ATT1;
--ATT_Cntl1B <= ATT2;
--ATT_Cntl1A <= ATT1;
--
  ATT_Cntl4B       <= not(ATT4(1) & ATT4(2) & ATT4(3) & ATT4(4));
  ATT_Cntl2B       <= not(ATT2(5) & ATT2(1) & ATT2(2) & ATT2(3) & ATT2(4));
--
  ATT_Cntl4A       <= not(ATT4(1) & ATT4(2) & ATT4(3) & ATT4(4));
  ATT_Cntl2A       <= not(ATT2(5) & ATT2(1) & ATT2(2) & ATT2(3) & ATT2(4));
--
  ATT_Cntl3B       <= not(ATT3(1) & ATT3(2) & ATT3(3) & ATT3(4));
  ATT_Cntl1B       <= not(ATT1(5) & ATT1(1) & ATT1(2) & ATT1(3) & ATT1(4));
--
  ATT_Cntl3A       <= not(ATT3(1) & ATT3(2) & ATT3(3) & ATT3(4));
  ATT_Cntl1A       <= not(ATT1(5) & ATT1(1) & ATT1(2) & ATT1(3) & ATT1(4));


  Attn_p : process(Red, Green, iATT1, iATT2)
  begin
    if (Red = '1') then
      ATT1 <= iATT2;
      ATT3 <= iATT1;
      ATT2 <= "11111";
      ATT4 <= "1111";
    elsif (Green = '1') then
      ATT1 <= "11111";
      ATT3 <= "1111";
      ATT2 <= iATT2;
      ATT4 <= iATT1;
    else
      ATT1 <= iATT2;
      ATT3 <= iATT1;
      ATT2 <= iATT2;
      ATT4 <= iATT1;
    end if;
  end process;  -- Attn_p

  CAL_ATT    <= not(iCAL_ATT(1)& iCAL_ATT(2) & iCAL_ATT(3) & iCAL_ATT(4) & iCAL_ATT(5));
--
  RS232_Rx   <= not(n_RS232_Rx);
  n_RS232_Tx <= not(RS232_Tx);

  QDin      <= Qspi_Din;
  QSPI_Dout <= iQDout;

  u_clk2x : clk2x
    port map (
      CLKIN_IN        => Local_Clock,
      RST_IN          => Reset,
      CLKIN_IBUFG_OUT => Clk60Mhz,
      CLK2X_OUT       => Clk120Mhz
      );

  u_clkdiv3 : clkdiv3
    port map(
      CLKIN_IN  => Clk60Mhz,
      RST_IN    => Reset,
      CLKDV_OUT => Clk20Mhz
      );

  SW_Trigger <= QSPI_Trig or RS232_Trig;

  u_trigcon : trigcon
    port map (
      Clock       => Clk120Mhz,
      Reset       => Reset,
      Sw_Trigger  => Sw_Trigger,
      Cal_Init    => Cal_init,
      Sys_Trigger => Sys_Trigger
      );

  u_handshake : trighandshake
    port map (
      Clock       => clk120mhz,
      Reset       => Reset,
      Sys_Trigger => Sys_Trigger,
      Triggered   => Triggered,
      Trig_reset  => Trig_reset
      );

  u_QSPI : QSPI
    port map (
      CLock      => QSPI_Clk,
      Reset      => Reset,
      Din        => QDin,
      Dout       => iQDout,
      CS         => QCs,
      Write_Strb => QWrStrb,
      DataOut    => QDataOut,
      Address    => QAddrOut,
      En         => QEn,
      DataIn     => RegDataOut
      );

  qspi_trig_p : process(QSPI_Clk, Reset)
  begin
    if (Reset = '1') then
      QSPI_Trig <= '0';
    elsif (QSPI_Clk'event and QSPI_Clk = '1') then
      if (QAddrOut = '1' & TRG_Addr(6 downto 0)) and (QWrStrb = '1') then
        QSPI_Trig <= '1';
      else
        QSPI_Trig <= '0';
      end if;
    end if;
  end process;

  u_rs232 : rs232intf
    port map (
      Clk   => Clk20Mhz,
      Reset => Reset,

-- Receiver
      Rx        => Rs232_Rx,
      RxDataOut => RxDataOut,
      RxAddrOut => RxAddrOut,
      WriteStrb => Rs232WrStrb,

-- Transmitter
      TxDataIn => RegDataOut,
      Tx       => Rs232_Tx,
      En       => Rs232En
      );

  rs232_trig_p : process(Clk20Mhz, Reset)
  begin
    if (Reset = '1') then
      RS232_Trig <= '0';
    elsif (Clk20Mhz'event and CLK20Mhz = '1') then
      if (RxAddrOut = '1' & TRG_Addr(6 downto 0)) and (Rs232WrStrb = '1') then
        RS232_Trig <= '1';
      else
        RS232_Trig <= '0';
      end if;
    end if;
  end process;

  u_RegSeq : regseq
    port map(
      CLK        => Clk20Mhz,
      Reset      => Reset,
--
      rs232Wr    => Rs232WrStrb,
      rs232DIn   => RxDataOut,
      rs232AIn   => RxAddrOut,
      rs232En    => Rs232En,
--
      qspiWr     => QWrStrb,
      qspiDIn    => QDataOut,
      qspiAIn    => QAddrOut,
      qspiEn     => QEn,
--
      Write_Strb => Write_Strb,
      DataOut    => RegDataIn,
      AddrOut    => RegAddress
      );


  u_BPMReg : bpm_reg
    port map (
      Clock      => Clk20Mhz,
      Reset      => Reset,
      Address    => RegAddress,
      Write_Strb => Write_Strb,
      DataIn     => RegDataIn,
      DataOut    => RegDataOut,
      ModeSel    => ModeSel,
      CalATT     => iCal_ATT,
      OscMode    => OscMode,
      ATT1       => iATT1,
      ATT2       => iATT2,
      Trip       => LMTR_Pulse,
--
      TRIG2AMP   => TRIG2AMP,
      AMP2RF1    => AMP2RF1,
      RF12RF2    => RF12RF2,
      RFWIDTH    => RFWIDTH,
      OFFTIME    => OFFTIME,
--
      TMS        => PROG_TMS,
      TCK        => PROG_TCK,
      TDI        => PROG_TDI,
      TDO        => PROG_TDO,
      Sel_Sec    => Sel_Sec,
      Sel_Clk    => Sel_Clk,
      Reboot     => Reboot,
      Lmtr_Long  => Force_Lmtr_long,
      Lmtr_Short => Force_Lmtr_Short

      );

  u_limiter : limiter
    port map (
      Clock         => clk20mhz,
      Reset         => Reset,
      LMT_Pulse     => LMTR_Pulse,
      LMT_Short_Rst => iLMTR_Short_Rst,
      LMT_Long_Rst  => iLMTR_Long_Rst
      );

  u_cal_seq : cal_seq
    port map (
      Clock       => clk120mhz,
      Reset       => Reset,
      Sys_Trigger => Sys_Trigger,
      ModeSel     => ModeSel,
      OscMode     => OscMode,
--
      TRIG2AMP    => TRIG2AMP,
      AMP2RF1     => AMP2RF1,
      RF12RF2     => RF12RF2,
      RFWIDTH     => RFWIDTH,
      OFFTIME     => OFFTIME,
--
      CAL_SW      => Cal_Sw,
      C2          => Red,
      C4          => Green,
      VAPC        => VAPC,
      OscOn       => Osc_On
      );

end behaviour;
