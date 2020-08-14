----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:30:23 03/05/2007 
-- Design Name: 
-- Module Name:    trigcon - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity trigcon is
  port (
    Clock       : in  std_logic;
    Reset       : in  std_logic;
    Sw_Trigger  : in  std_logic;
    Cal_Init    : in  std_logic;
    Sys_Trigger : out std_logic
    );

end trigcon;

architecture Behavioral of trigcon is

  signal SW_TrigSr  : std_logic_vector(2 downto 0);
  signal Cal_TrigSr : std_logic_vector(2 downto 0);

begin
  trig_p : process(clock, reset)
  begin
    if (reset = '1') then
      Sw_TrigSr  <= (others => '0');
      Cal_TrigSr <= (others => '0');
    elsif (clock'event and clock = '1') then
      Sw_TrigSr  <= Sw_TrigSr(1 downto 0) & Sw_Trigger;
      Cal_TrigSr <= Cal_TrigSr(1 downto 0) & Cal_Init;
      if ((Sw_Trigsr(2 downto 1) = "01") or (Cal_TrigSr(2 downto 1) = "01")) then
        Sys_Trigger <= '1';
      else
        Sys_Trigger <= '0';
      end if;
    end if;
  end process;
end Behavioral;

