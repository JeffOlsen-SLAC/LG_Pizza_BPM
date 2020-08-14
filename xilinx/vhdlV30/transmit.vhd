-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      transmit.vhd - 
--
--      Copyright(c) SLAC 2000
--
--      Author: Jeff Olsen
--      Created on: 10/23/2006 3:21:40 PM
--      Last change: JO 10/26/2006 4:19:11 PM
--
-- 
-- Created by Jeff Olsen 6/27/00
--
--  Filename: transmit.vhd
--
--  Function:
--  Transmit bytes to rs232_tx
--  
--  Modifications:
--
-- 10/11/06
-- This code is being modifed from the Franken Board code
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library work;
use work.bpm.all;

entity transmit is

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
end transmit;

architecture BEHAVIOUR of transmit is

  type transmit_t is
    (
      Send_0,
      Send_X,
      Send_Data,
      Send_CR,
      Send_Byte,
      Term
      );

  signal transmitState : transmit_t;
  signal NextState     : transmit_t;
--
  signal ByteCnt       : std_logic_vector(3 downto 0);
  signal LdByteCnt     : std_logic;
  signal DnByteCnt     : std_logic;
  signal LdDataSr      : std_logic;
  signal EnDataSr      : std_logic;
  signal DataSr        : std_logic_vector(15 downto 0);
--
  signal TSum          : std_logic_vector(7 downto 0);


begin


  Add_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      TSum <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (DataSr(15 downto 12) > "1001") then
        TSum <= ("0000" & DataSr(15 downto 12)) + "00110111";
      else
        TSum <= ("0000" & DataSr(15 downto 12)) + "00110000";
      end if;
    end if;
  end process;  -- Add_p;


  ByteCnt_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      ByteCnt <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (LdByteCnt = '1') then
        ByteCnt <= "0011";
      elsif (DnByteCnt = '1') then
        ByteCnt <= ByteCnt - 1;
      else
        ByteCnt <= ByteCnt;
      end if;
    end if;
  end process;  -- BitCnt_p

  DataSR_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      DataSr <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (LdDataSr = '1') then
        DataSR <= Addr & DataIn;
      elsif (EnDataSr = '1') then

        DataSr(15 downto 12) <= DataSr(11 downto 8);
        DataSr(11 downto 8)  <= DataSr(7 downto 4);
        DataSr(7 downto 4)   <= DataSr(3 downto 0);
        DataSr(3 downto 0)   <= "0000";
      else
        DataSr(15 downto 0) <= DataSr(15 downto 0);
      end if;
    end if;
  end process;  -- DataSr_p

  transmitSM : process(CLK, Reset)
  begin
    if (Reset = '1') then
      transmitState <= Send_0;
    elsif (CLK'event and CLK = '1') then
      transmitState <= NextState;
    end if;
  end process;  -- transmitSM


  Tx_p : process(TransmitState, NextState, ByteCnt, NewData, TxDone, TSum, Addr, DataIn)
  begin
    case transmitState is

      when Send_0 =>
        DnByteCnt <= '0';
        LdByteCnt <= '1';
        EnDout    <= '0';
--  
        if (NewData = '1') then
          LdDataSr <= '1';
          Xmit     <= '1';
          EnDataSr <= '1';
          EnDout   <= '1';
-- Binary Mode
          if (addr(7) = '1') then
            DataOut   <= "11" & Addr(5 downto 0);
            NextState <= Send_Byte;
          else
            DataOut   <= "00110000";
            NextState <= Send_x;
          end if;

        else
          EnDout    <= '0';
          LdDataSr  <= '0';
          Xmit      <= '0';
          EnDataSr  <= '0';
          DataOut   <= "00000000";
          NextState <= Send_0;
        end if;

      when Send_X =>
        DnByteCnt <= '0';
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        EnDataSr  <= '0';
        DataOut   <= "01011000";
-- X = 58\h
        if (TxDone = '1') then
          Xmit      <= '1';
          EnDout    <= '1';
          NextState <= Send_Data;
        else
          EnDout    <= '0';
          Xmit      <= '0';
          NextState <= Send_X;
        end if;

      when Send_Data =>
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        DataOut   <= TSum;
        EnDout    <= '1';

        if (TxDone = '1') then
          Xmit      <= '1';
          DnByteCnt <= '1';
          EnDataSr  <= '1';

          if (ByteCnt = "0000") then
            NextState <= Send_Cr;
          else
            NextState <= Send_Data;
          end if;
        else
          Xmit      <= '0';
          EnDataSr  <= '0';
          DnByteCnt <= '0';
          NextState <= Send_Data;
        end if;


      when Send_CR =>
        DnByteCnt <= '0';
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        EnDataSr  <= '0';
        DataOut   <= "00001101";
        EnDout    <= '0';

-- CR = 0D\h
        if (TxDone = '1') then
          Xmit      <= '1';
          NextState <= Term;
        else
          Xmit      <= '0';
          NextState <= Send_Cr;
        end if;

      when Send_Byte =>
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        EnDout    <= '1';

        DataOut   <= '0' & DataIn(6 downto 0);
        DnByteCnt <= '1';
        EnDataSr  <= '1';

        if (TxDone = '1') then
          Xmit      <= '1';
          NextState <= Term;
        else
          Xmit      <= '0';
          NextState <= Send_Byte;
        end if;

      when Term =>
        DnByteCnt <= '0';
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        EnDataSr  <= '0';
        Xmit      <= '0';
        EnDout    <= '0';
        DataOut   <= TSum;

        NextState <= Send_0;

      when others =>
        DnByteCnt <= '0';
        LdByteCnt <= '0';
        LdDataSr  <= '0';
        EnDataSr  <= '0';
        Xmit      <= '0';
        DataOut   <= TSum;
        EnDout    <= '0';

        NextState <= Send_0;



    end case;
  end process;  -- transmit

end Behaviour;

