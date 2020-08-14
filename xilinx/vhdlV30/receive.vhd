-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      receive.vhd - 
--
--      Copyright(c) SLAC 2000
--
--      Author: Jeff Olsen
--      Created on: 10/23/2006 3:01:34 PM
--      Last change: JO 10/26/2006 4:15:06 PM
--
-- 
-- Created by Jeff Olsen 6/27/00
--
--  Filename: receive.vhd
--
--  Function:
--  Receive bytes from rs232_rx and check packet validity
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

entity receive is

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
end receive;

architecture BEHAVIOUR of receive is

  type receive_t is
    (
      Wait_0,
      Wait_X,
      Wait_Addr1,
      Wait_Addr2,
      Wait_Byte,
      Wait_CR,
      BinaryIn,
      Term
      );

  signal ReceiveState : Receive_t;
  signal NextState    : Receive_t;
--
  signal ByteCnt      : std_logic_vector(2 downto 0);
  signal LdByteCnt    : std_logic;
  signal DnByteCnt    : std_logic;
  signal LdAddr       : std_logic;
  signal LdCmd        : std_logic;
  signal LdDat        : std_logic;
--
  signal iValid       : std_logic;
  signal iEn          : std_logic;
  signal validByte    : std_logic;
  signal tdiff        : std_logic_vector(7 downto 0);
  signal TSub         : std_logic_vector(7 downto 0);
  signal dDAV         : std_logic;
  signal Dav0         : std_logic;
  signal iData        : std_logic_vector(7 downto 0);
  signal Rs232Rd      : std_logic;
  signal Read         : std_logic;
  signal iAddr        : std_logic_vector(7 downto 0);
  signal LdBinaryAddr : std_logic;
  signal LdBinaryData : std_logic;


begin

  Data <= iData;
  Addr <= iAddr;


  Rs232Rd_p : process(TDIff)
  begin
    if (TDIFF(3) = '1') then
      Rs232Rd <= '1';
    else
      Rs232Rd <= '0';
    end if;
  end process;  --Rs232Rd_p:



  Sub_P : process(clk, reset)
  begin
    if (reset = '1') then
      TDiff <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      TDiff <= DataIn - TSub;
    end if;
  end process;  -- Sub_p

  ValidByte_p : process(DataIn)
  begin

    if ((DataIn >= "00110000") and (DataIn <= "00111001")) then
      TSub      <= "00110000";
      ValidByte <= '1';
    elsif ((DataIn >= "01000001") and (DataIn <= "01000110")) then
      TSub      <= "00110111";
      ValidByte <= '1';
    else
      TSub      <= "00000000";
      ValidByte <= '0';
    end if;

  end process;  -- ValidByte_p

  Valid_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      Valid <= '0';
      En    <= '0';
    elsif (CLK'event and CLK = '1') then
      Valid <= iValid;
      En    <= iEn;
    end if;
  end process;  -- Valid_p

  dDAV_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      dDAV <= '0';
      Dav0 <= '0';
    elsif (CLK'event and CLK = '1') then
      Dav0 <= DAV;
      dDAV <= Dav0;
    end if;
  end process;  -- dDAV_p 


  Addr_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      Read              <= '0';
      iAddr(7 downto 0) <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (LdAddr = '1') then
        iAddr(7 downto 4) <= iAddr(3 downto 0);
        iAddr(3 downto 0) <= TDiff(3 downto 0);

        if (ReceiveState = Wait_Addr1) then
          Read <= TDIFF(2);
        end if;
      end if;
      if (LdBinaryAddr = '1') then
        iAddr <= DataIn;
        Read  <= DataIn(6);
      end if;
    end if;
  end process;  -- Addr_p


  ByteCnt_p : process(CLK, Reset)
  begin
    if (Reset = '1') then
      ByteCnt <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (LdByteCnt = '1') then
        ByteCnt <= "001";
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
      iData <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (LdDat = '1') then
        iData(7 downto 4) <= iData(3 downto 0);
        iData(3 downto 0) <= Tdiff(3 downto 0);
      else
        iData(7 downto 0) <= iData(7 downto 0);
      end if;

      if (LdBinaryData = '1') then
        iData <= DataIn;
      end if;
    end if;
  end process;  -- DataSr_p

  ReceiveSM : process(CLK, Reset)
  begin
    if (Reset = '1') then
      ReceiveState <= Wait_0;
    elsif (CLK'event and CLK = '1') then
      ReceiveState <= NextState;
    end if;
  end process;  -- ReceiveSM


  Tx_p : process(ReceiveState, NextState, ByteCnt, dDAV, Parity, DATAIn, ValidByte, Rs232rd, Read)
  begin
    case ReceiveState is

      when Wait_0 =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '1';
        LdAddr       <= '0';
        LdCmd        <= '0';
        LdDat        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';


        if (dDAV = '1') then
          if ((Parity = '0') and (DataIn = "00110000")) then
            iEn       <= '0';
            NextState <= Wait_X;
          elsif ((Parity = '0') and (DataIn(7) = '1')) then  -- Binary
            iEn          <= '1';
            LdBinaryAddr <= '1';
            if (DataIn(6) = '0') then                        -- Read
              NextState <= BinaryIn;
            else
              NextState <= Term;
            end if;
          else
            iEn          <= '0';
            LdBinaryAddr <= '0';
            NextState    <= Wait_0;
          end if;
        else
          iEn          <= '0';
          LdBinaryAddr <= '0';
          NextState    <= Wait_0;
        end if;

      when Wait_X =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        LdDat        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '0';

        if (dDAV = '1') then
          if ((Parity = '0') and (DataIn = "01011000")) then
            NextState <= Wait_Addr1;
          else
            NextState <= Wait_0;
          end if;
        else
          NextState <= Wait_X;
        end if;

      when Wait_Addr1 =>

        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdCmd        <= '0';
        LdDat        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '1';

        if (dDAV = '1') then
          if ((Parity = '0') and (ValidByte = '1')) then
            LdAddr    <= '1';
            NextState <= Wait_Addr2;
          else
            LdAddr    <= '0';
            NextState <= Wait_0;
          end if;
        else
          LdAddr    <= '0';
          NextState <= Wait_Addr1;
        end if;

      when Wait_Addr2 =>

        DnByteCnt    <= '0';
        LdByteCnt    <= '1';
        LdCmd        <= '0';
        LdDat        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '1';

        if (dDAV = '1') then
          if ((Parity = '0') and (ValidByte = '1')) then
            LdAddr <= '1';
            if (Read = '1') then
              NextState <= Wait_CR;
            else
              NextState <= Wait_Byte;
            end if;
          else
            LdAddr    <= '0';
            NextState <= Wait_0;
          end if;
        else
          LdAddr    <= '0';
          NextState <= Wait_Addr2;
        end if;


      when Wait_Byte =>
        LdByteCnt    <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '1';

        if (dDAV = '1') then
          DnByteCnt <= '1';
          if ((Parity = '0') and (ValidByte = '1')) then
            LdDat <= '1';
            if (ByteCnt = "000") then
              NextState <= Wait_CR;
            else
              NextState <= Wait_Byte;
            end if;
          else
            LdDat     <= '0';
            NextState <= Wait_0;
          end if;
        else
          DnByteCnt <= '0';
          LdDat     <= '0';
          NextState <= Wait_Byte;
        end if;

      when Wait_CR =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdDat        <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '1';

        if (dDAV = '1') then
          if ((Parity = '0') and (DataIn = "00001101")) then
            NextState <= Term;
          else
            NextState <= Wait_0;
          end if;
        else
          NextState <= Wait_CR;
        end if;

      when BinaryIn =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdDat        <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        iValid       <= '0';
        DnByteCnt    <= '0';
        LdBinaryAddr <= '0';
        iEn          <= '1';

        if (dDAV = '1') then
          if ((Parity = '0') and (DataIn(7) = '0')) then
            LdBinaryData <= '1';
            NextState    <= Term;
          else
            LdBinaryData <= '0';
            NextState    <= Wait_0;
          end if;
        else
          LdBinaryData <= '0';
          NextState    <= BinaryIn;
        end if;

      when Term =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdDat        <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        iValid       <= '1';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '1';

        NextState <= Wait_0;



      when others =>
        DnByteCnt    <= '0';
        LdByteCnt    <= '0';
        LdDat        <= '0';
        LdAddr       <= '0';
        LdCmd        <= '0';
        iValid       <= '0';
        LdBinaryAddr <= '0';
        LdBinaryData <= '0';
        iEn          <= '0';

        NextState <= Wait_0;



    end case;
  end process;  -- receive

end Behaviour;

