-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  limiter.vhd - 
--
--  Copyright(c) Stanford Linear Accelerator Center 2000
--
--  Author: JEFF OLSEN
--  Created on: 8/4/2006 11:56:00 AM
--  Last change: JO 1/18/2007 4:23:46 PM
--

-- 11/16/06 jjo
-- Changed long reset to a Retriggerable one shot
--

library work;
use work.bpm.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity limiter is
  port (
    Clock         : in  std_logic;
    Reset         : in  std_logic;
    LMT_Pulse     : in  std_logic;
    LMT_Short_Rst : out std_logic;
    LMT_Long_Rst  : out std_logic
    );
end limiter;


architecture Behaviour of limiter is

  signal Short_Delay   : std_logic_vector(15 downto 0);
  signal Short_Width   : std_logic_vector(15 downto 0);
  signal Long_Delay    : std_logic_vector(15 downto 0);
  signal Long_Width    : std_logic_vector(15 downto 0);
--
  signal trigger       : std_logic;
  signal TrigSr        : std_logic_vector(2 downto 0);
  signal sel           : std_logic_vector(1 downto 0);
  signal OS_Out        : std_logic;
  signal FallingEdgeSr : std_logic_vector(1 downto 0);

begin

  Falling_p : process(Clock, Reset)
  begin
    if (Reset = '1') then
      LMT_Long_Rst  <= '0';
      FallingEdgeSr <= (others => '0');
    elsif (Clock'event and Clock = '1') then
      FallingEdgeSr <= FallingEdgeSr(0) & OS_Out;
      if (FallingEdgeSr = "10") then
        LMT_Long_Rst <= '1';
      else
        LMT_Long_Rst <= '0';
      end if;
    end if;
  end process;  -- Falling_p

  Trig_p : process(Clock, Reset)
  begin
    if (Reset = '1') then
      Trigger <= '0';
      TrigSr  <= (others => '0');
    elsif (Clock'event and Clock = '1') then
      TrigSr(2 downto 0) <= TrigSr(1 downto 0) & LMT_Pulse;
      if (TrigSr(2 downto 1) = "01") then
        Trigger <= '1';
      else
        Trigger <= '0';
      end if;
    end if;
  end process;  -- Trig_p

  Short_Delay <= LMTR_Short_Delay;
  Short_Width <= LMTR_Short_Width;
  Long_Delay  <= LMTR_Long_Delay;
  Long_Width  <= LMTR_Long_Width;


  ShortRst1 : prog_strobe
    port map (
      Clock     => Clock,
      reset     => reset,
      TriggerIn => Trigger,
      Delay     => Short_Delay,
      Width     => Short_Width,
      Pulse     => LMT_Short_Rst
      );


  LongRst1 : oneshot
    port map(
      Clock    => Clock,
      Reset    => reset,
      Start    => TrigSr(0),
      RetrigEn => '1',
      Level    => '1',
      OS_Time  => Long_Delay,
      OS_Out   => Os_Out
      );
end behaviour;
