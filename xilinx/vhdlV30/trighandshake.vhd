-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  trighandshake.vhd - 
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

entity trighandshake is
  port (
    Clock       : in  std_logic;
    Reset       : in  std_logic;
    Sys_Trigger : in  std_logic;
    Triggered   : out std_logic;
    Trig_reset  : in  std_logic
    );
end trighandshake;


architecture Behaviour of trighandshake is

  signal handshakeSr : std_logic_vector(2 downto 0);
  signal iTrig_reset : std_logic;

begin

  Reset_sync : process(Clock, Reset)
  begin
    if (reset = '1') then
      handshakeSr <= (others => '0');
    elsif (clock'event and clock = '1') then
      handshakeSr <= handshakeSr(1 downto 0) & Trig_reset;
      if (handshakeSr(2 downto 1) = "01") then
        iTrig_reset <= '1';
      else
        iTrig_Reset <= '0';
      end if;
    end if;
  end process;


  handshake_p : process(Clock, Reset)
  begin
    if (reset = '1') then
      Triggered <= '0';
    elsif (clock'event and clock = '1') then
      if (Sys_Trigger = '1') then
        Triggered <= '1';
      elsif (iTrig_reset = '1') then
        Triggered <= '0';
      end if;
    end if;
  end process;

end behaviour;
