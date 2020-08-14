-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  rs232_rx.vhd - 
--
--  Copyright(c) SLAC 2000
--
--  Author: Jeff Olsen
--  Created on: 10/26/2006 4:14:15 PM
--  Last change: JO  10/26/2006 4:14:15 PM
--
-- 
-- Created by Jeff Olsen 6/27/00
--
--  Filename: RS232_rx.vhd
--
--  Function:
--  Receive 19.2KBd Serial Data using 20Mhz clk
--  
--  Modifications:
--  03/15/02 jjo
--  Added 9600 baud rate
--  Increased NBitWidth from 11 to 12

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library work;
use work.bpm.all;

entity rs232_rx is

  port (
    RxCLK    : in  std_logic;
    Reset    : in  std_logic;
    RxDin    : in  std_logic;
    RxData   : out std_logic_vector(7 downto 0);
    RxDone   : out std_logic;
    RxParity : out std_logic
    );
end rs232_rx;

architecture BEHAVIOUR of rs232_rx is

-- 03/15/02 changed NbitWidth from 10 to 11

  constant NBits     : integer := 10;   -- N-1
  constant NBitwidth : integer := 11;   -- N-1
  constant NBitCnt   : integer := 3;

-- 9600kBd
--Constant BitWidth     : std_logic_vector(NBitWidth downto 0)  := "100000100011"; -- 2083 (823)
--Constant BitWidth2    : std_logic_vector(NBitWidth downto 0)  := "010000010001"; 


-- 19200kBd
--Constant BitWidth     : std_logic_vector(NBitWidth downto 0)  := "010000010010"; -- 1042 (412)
--Constant BitWidth2    : std_logic_vector(NBitWidth downto 0)  := "001000001001"; 

-- 38400kBd
--Constant BitWidth     : std_logic_vector(NBitWidth downto 0)  := "010100100000"; -- 520 (208)
--Constant BitWidth2    : std_logic_vector(NBitWidth downto 0)  := "001010010000"; 

-- 57600kBd
--Constant BitWidth     : std_logic_vector(NBitWidth downto 0)  := "000101011011"; -- 347 (15B)
--Constant BitWidth2    : std_logic_vector(NBitWidth downto 0)  := "000010101101"; 

-- 115200kBd
  constant BitWidth  : std_logic_vector(NBitWidth downto 0) := "000010101110";  -- 174 (AE)
  constant BitWidth2 : std_logic_vector(NBitWidth downto 0) := "000001010111";


  type RXState_t is
    (
      Idle,
      Start,
      Rx,
      Term
      );

  signal RXState   : RXState_t;
  signal NextState : RXState_t;

  signal RxSR   : std_logic_vector(NBits downto 0);
  signal EnRxSr : std_logic;

  signal LdParity  : std_logic;
  signal EnParity  : std_logic;
  signal iRxParity : std_logic;

  signal BitWidthCnt   : std_logic_vector(NbitWidth downto 0);
  signal NextWidthCnt  : std_logic_vector(NBitWidth downto 0);
  signal LdBitWidthCnt : std_logic;
  signal DnBitWidthCnt : std_logic;

  signal BitCnt   : std_logic_vector(NBitCnt downto 0);
  signal LdBitCnt : std_logic;
  signal DnBitCnt : std_logic;

  signal iRxDone : std_logic;
  signal iRxData : std_logic_vector(7 downto 0);

  signal IFilter : std_logic_vector(3 downto 0);
  signal FDIN    : std_logic;

begin


  RxData   <= iRxData;
  RxParity <= iRxParity;

  Filter : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      iFilter <= "0000";
    elsif (RxCLK'event and RxCLK = '1') then
      iFilter(0)          <= RxDin;
      iFilter(3 downto 1) <= iFilter(2 downto 0);
    end if;
  end process;  --Filter

  FDin_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      FDin <= '0';
    elsif (RxCLK'event and RxCLK = '1') then
      if (iFilter = "1111") then
        FDin <= '1';
      elsif (iFilter = "0000") then
        FDin <= '0';
      else
        FDin <= FDin;
      end if;
    end if;
  end process;  -- FDin_p       

  RxDone_p : process(RxCLK, Reset)
  begin
    if (reset = '1') then
      RxDone <= '0';
    elsif (RxCLK'event and RxCLK = '1') then
      RxDone <= iRxDone;
    end if;
  end process;  -- RxDone_p

  Parity_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      iRxParity <= '0';
    elsif (RxCLK'event and RxCLK = '1') then
      if (LdParity = '1') then
        iRxParity <= '1';
      elsif (EnParity = '1') then
        iRxParity <= (iRxParity xor FDin);
      else
        iRxParity <= iRxParity;
      end if;
    end if;
  end process;  -- Parity_p

  BitCnt_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      BitCnt <= (others => '0');
    elsif (RxCLK'event and RxCLK = '1') then
      if (LdBitCnt = '1') then
        BitCnt <= "1010";
      elsif (DnBitCnt = '1') then
        BitCnt <= BitCnt - 1;
      else
        BitCnt <= BitCnt;
      end if;
    end if;
  end process;  -- BitCnt_p

  BitWidthCnt_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      BitWidthCnt <= (others => '0');
    elsif (RxCLK'event and RxCLK = '1') then
      if (LdBitWidthCnt = '1') then
        BitWidthCnt <= NextWidthCnt;
      elsif (DnBitWidthCnt = '1') then
        BitWidthCnt <= BitWidthCnt - 1;
      else
        BitWidthCnt <= BitWidthCnt;
      end if;
    end if;
  end process;  -- BitWidthCnt_p



-- LSB first for RS232

  RxSr_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      RxSR <= (others => '0');
    elsif (RxCLK'event and RxCLK = '1') then
      if (EnRxSR = '1') then
        RxSR(NBits-1 downto 0) <= RxSR(NBits downto 1);
        RxSr(NBits)            <= FDin;
      else
        RxSR <= RxSR;
      end if;
    end if;
  end process;  -- TxSR_p


  RxData_p : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      iRxData <= (others => '0');
    elsif (RxCLK'event and RxCLK = '1') then
      if (iRxDone = '1') then
        iRxData(7 downto 0) <= not(RxSr(8 downto 1));
      else
        iRxData <= iRxData;
      end if;
    end if;
  end process;  -- RxData

  RxSm : process(RxCLK, Reset)
  begin
    if (Reset = '1') then
      RxState <= IDLE;
    elsif (RxCLK'event and RxCLK = '1') then
      RxState <= NextState;
    end if;
  end process;  -- RxSM


  Tx_p : process(RxState, NextState, BitCnt, BitWidthCnt, FDIN)
  begin
    case RxState is

      when Idle =>
        DnBitCnt      <= '0';
        DnBitWidthCnt <= '0';
        LdBitWidthCnt <= '1';
        EnRxSr        <= '0';
        LdParity      <= '0';
        EnParity      <= '0';
        iRxDone       <= '0';
        NextWidthCnt  <= BitWidth2;
        if (FDin = '1') then
          LdBitCnt  <= '1';
          NextState <= Start;
        else
          LdBitCnt  <= '0';
          NextState <= Idle;
        end if;

      when Start =>
        iRxDone      <= '0';
        LdBitCnt     <= '0';
        EnParity     <= '0';
        NextWidthCnt <= BitWidth;
        if (BitWidthCnt = "00000") then
          LdParity      <= '1';
          EnRxSr        <= '1';
          DnBitWidthCnt <= '0';
          LdBitWidthCnt <= '1';
          DnBitCnt      <= '1';
          NextState     <= Rx;
        else
          LdParity      <= '0';
          EnRxSr        <= '0';
          DnBitWidthCnt <= '1';
          LdBitWidthCnt <= '0';
          DnBitCnt      <= '0';
          NextState     <= Start;
        end if;

      when Rx =>
        iRxDone      <= '0';
        LdBitCnt     <= '0';
        NextWidthCnt <= BitWidth;
        if (BitWidthCnt = "00000") then
          LdParity      <= '0';
          EnParity      <= '1';
          EnRxSr        <= '1';
          DnBitWidthCnt <= '0';
          LdBitWidthCnt <= '1';
          DnBitCnt      <= '1';
          if (BitCnt = "0000") then
            NextState <= Term;
          else
            NextState <= Rx;
          end if;
        else
          LdParity      <= '0';
          EnParity      <= '0';
          EnRxSr        <= '0';
          DnBitWidthCnt <= '1';
          LdBitWidthCnt <= '0';
          DnBitCnt      <= '0';
          NextState     <= Rx;

        end if;

      when Term =>
        iRxDone       <= '1';
        LdBitCnt      <= '0';
        DnBitCnt      <= '0';
        EnRxSr        <= '0';
        LdParity      <= '0';
        EnParity      <= '0';
        DnBitWidthCnt <= '0';
        LdBitWidthCnt <= '0';
        NextWidthCnt  <= BitWidth;
        NextState     <= Idle;

      when others =>
        iRxDone       <= '0';
        LdBitCnt      <= '0';
        DnBitCnt      <= '0';
        EnRxSr        <= '0';
        LdParity      <= '0';
        EnParity      <= '0';
        DnBitWidthCnt <= '0';
        LdBitWidthCnt <= '0';
        NextWidthCnt  <= BitWidth;
        NextState     <= Idle;


    end case;
  end process;  -- Tx_P

end Behaviour;

