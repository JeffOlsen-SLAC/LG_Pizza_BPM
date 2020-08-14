-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  bpm_reg.vhd - 
--
--  Copyright(c) Stanford Linear Accelerator Center 2000
--
--  Author: JEFF OLSEN
--  Created on: 8/4/2006 9:52:00 AM
--  Last change: JO 12/13/2007 5:01:24 PM
--

library work;
use work.bpm.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity bpm_reg is
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
    TDI        : out std_logic;         -- to PROM TDI
    TDO        : in  std_logic;         -- from PROM TDO
    Sel_Sec    : out std_logic;
    Sel_Clk    : out std_logic;
    Reboot     : out std_logic;
    Lmtr_Long  : out std_logic;
    Lmtr_Short : out std_logic
    );
end bpm_reg;

architecture Behaviour of bpm_reg is

  signal CSRReg       : std_logic_vector(5 downto 0);
  signal CALReg       : std_logic_vector(4 downto 0);
  signal ATT1Reg      : std_logic_vector(3 downto 0);
  signal ATT2Reg      : std_logic_vector(4 downto 0);
  signal LMTReg       : std_logic;
  signal BootReg      : std_logic_vector(2 downto 0);
  signal JTAGReg      : std_logic_vector(2 downto 0);
--
  signal iAddress     : std_logic_vector(7 downto 0);
--
  signal Trig2AMP_Reg : std_logic_vector(7 downto 0);
  signal AMP2RF1_Reg  : std_logic_vector(7 downto 0);
  signal RF12RF2_Reg  : std_logic_vector(7 downto 0);
  signal RFWidth_Reg  : std_logic_vector(7 downto 0);
  signal OffTime_Reg  : std_logic_vector(7 downto 0);


begin
-- 01/18/07 jjo
-- Added registers

-- MSB is Read/Write
  iAddress   <= "00" & Address(5 downto 0);
--
  Lmtr_Long  <= CSRReg(5);
  Lmtr_Short <= CSRReg(4);
--
  ModeSel    <= CSRReg(1 downto 0);
  CalATT     <= CALReg(4 downto 0);
  ATT1       <= ATT1Reg(3 downto 0);
  ATT2       <= ATT2Reg(4 downto 0);
--
  Reboot     <= BootReg(2);
  Sel_Sec    <= BootReg(1);
  Sel_Clk    <= BootReg(0);
--
  TCK        <= JTAGReg(2);
  TDI        <= JTAGReg(1);
  TMS        <= JTAGReg(0);
--
  TRIG2AMP   <= TRIG2AMP_Reg;
  AMP2RF1    <= AMP2RF1_Reg;
  RF12RF2    <= RF12RF2_Reg;
  RFWIDTH    <= RFWidth_Reg;
  OFFTIME    <= OFFTIME_Reg;


  WriteReg_p : process(Clock, Reset)
  begin
    if (Reset = '1') then
      CSRReg       <= "000010";
      CALReg       <= "11111";
      ATT1Reg      <= "1111";
      ATT2Reg      <= "11111";
      LMTReg       <= '0';
      BootReg      <= "000";
--
      Trig2AMP_Reg <= Trig2AMP_Default;
      AMP2RF1_Reg  <= AMP2RF1_Default;
      RF12RF2_Reg  <= RF12RF2_Default;
      RFWidth_Reg  <= RFWidth_Default;
      OffTime_Reg  <= OffTime_Default;

      JTAGReg <= "000";

    elsif (clock'event and clock = '1') then
      if (Write_Strb = '1') then
        case iAddress is
          when CSR_Addr =>
            CSRReg <= DataIn(5 downto 0);
          when CAL_Addr =>
            if (DataIn > x"1F") then
              CALReg <= "11111";
            else
              CALReg <= DataIn(4 downto 0);
            end if;
          when ATT1_Addr =>
            if (DataIn > x"0F") then
              ATT1Reg <= "1111";
            else
              ATT1Reg <= DataIn(3 downto 0);
            end if;
          when ATT2_Addr =>
            if (DataIn > x"1F") then
              ATT2Reg <= "11111";
            else
              ATT2Reg <= DataIn(4 downto 0);
            end if;

          when LMT_Addr =>
            LMTReg <= ((LMTReg or Trip) and not(DataIn(0)));
          when Trig2AMP_Addr =>
            Trig2AMP_Reg <= DataIn(7 downto 0);
          when AMP2RF1_Addr =>
            AMP2RF1_Reg <= DataIn(7 downto 0);
          when RF12RF2_Addr =>
            RF12RF2_Reg <= DataIn(7 downto 0);
          when RFWidth_Addr =>
            RFWidth_Reg <= DataIn(7 downto 0);
          when OffTime_Addr =>
            OffTime_Reg <= DataIn(7 downto 0);

          when Boot_Addr =>
            BootReg <= DataIn(2 downto 0);
          when JTAG_Addr =>
            JTAGReg <= DataIn(2 downto 0);
          when others =>
        end case;
      else
      end if;
    end if;
  end process;  --WriteReg_p

  ReadReg_p : process(iAddress, CSRReg, CALReg, ATT1Reg, ATT2Reg,
                      LMTReg, JTAGReg, TDO, BootReg, Trig2AMP_Reg,
                      AMP2RF1_Reg, RF12RF2_Reg, RFWidth_Reg, OffTime_Reg)
  begin
    case iAddress is
      when CSR_Addr =>
        DataOut <= "00" & CSRReg(5 downto 3) & '0' & CSRReg(1 downto 0);
      when CAL_Addr =>
        DataOut <= "000" & CALReg(4 downto 0);
      when ATT1_Addr =>
        DataOut <= "0000" & ATT1Reg;
      when ATT2_Addr =>
        DataOut <= "000" & ATT2Reg;
      when LMT_Addr =>
        DataOut <= "0000000" & LMTReg;
      when VER_Addr =>
        DataOut <= "0" & Version;

      when Trig2AMP_Addr =>
        DataOut <= Trig2AMP_Reg;
      when AMP2RF1_Addr =>
        DataOut <= AMP2RF1_Reg;
      when RF12RF2_Addr =>
        DataOut <= RF12RF2_Reg;
      when RFWidth_Addr =>
        DataOut <= RFWidth_Reg;
      when OffTime_Addr =>
        DataOut <= OffTime_Reg;


      when Boot_Addr =>
        DataOut <= "00000" & BootReg;
      when JTAG_Addr =>
        DataOut <= "0000" & TDO & JTAGReg(2 downto 0);
      when others =>
        DataOut <= (others => '0');
    end case;

  end process;  --ReadReg_p

end Behaviour;




