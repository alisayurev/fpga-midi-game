library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART is
    Port (
        clk          : in  STD_LOGIC;
        reset        : in  STD_LOGIC; -- stops transmitting or receiving and resets internal signals
        tx_start     : in  STD_LOGIC; -- initiates a transmission when set to '1'
        tx_data      : in  STD_LOGIC_VECTOR(7 downto 0); -- data
        tx           : out STD_LOGIC; -- serial output for transmitting data
        tx_busy      : out STD_LOGIC; -- if set to '1', the transmitter is sending data
        
        rx           : in  STD_LOGIC; -- serial input for reading data
        rx_data      : out STD_LOGIC_VECTOR(7 downto 0); -- holds the data byte
        rx_ready     : out STD_LOGIC -- set to '1' once an entire byte has been read
    );
end UART;

architecture Behavioral of UART is

    constant CLK_FREQ : integer := 50000000; -- 50 MHz clock frequency
    constant BAUD_RATE : integer := 9600;    -- UART baud rate
    constant BAUD_COUNTER_MAX : integer := CLK_FREQ / BAUD_RATE;

    -- Transmitter signals
    signal tx_counter    : integer range 0 to BAUD_COUNTER_MAX := 0;
    signal tx_shift_reg  : STD_LOGIC_VECTOR(9 downto 0); -- 1 start bit, 8 data bits, 1 stop bit
    signal tx_bit_index  : integer range 0 to 9 := 0;
    signal tx_active     : STD_LOGIC := '0';

    -- Receiver signals
    signal rx_counter    : integer range 0 to BAUD_COUNTER_MAX := 0;
    signal rx_shift_reg  : STD_LOGIC_VECTOR(9 downto 0);
    signal rx_bit_index  : integer range 0 to 9 := 0;
    signal rx_sampling   : STD_LOGIC := '0';
    signal rx_active     : STD_LOGIC := '0';

begin

    -- Transmitter process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tx <= '1';
                tx_busy <= '0';
                tx_active <= '0';
                tx_counter <= 0;
            elsif tx_start = '1' and tx_busy = '0' then -- waits until ready
                -- Load start bit, data, and stop bit
                tx_shift_reg <= '0' & tx_data & '1'; -- Start bit, data, stop bit
                tx_bit_index <= 0;
                tx_busy <= '1';
                tx_active <= '1';
            elsif tx_active = '1' then
                if tx_counter = BAUD_COUNTER_MAX then
                    tx <= tx_shift_reg(tx_bit_index);
                    tx_bit_index <= tx_bit_index + 1;
                    tx_counter <= 0;
                    
                    if tx_bit_index = 9 then
                        tx_active <= '0';
                        tx_busy <= '0';
                    end if;
                else
                    tx_counter <= tx_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Receiver process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_ready <= '0';
                rx_active <= '0';
                rx_sampling <= '0';
                rx_counter <= 0;
            elsif rx_active = '0' and rx = '0' then
                -- Start bit detected
                rx_active <= '1';
                rx_counter <= BAUD_COUNTER_MAX / 2;
                rx_bit_index <= 0;
            elsif rx_active = '1' then
                if rx_counter = BAUD_COUNTER_MAX then
                    rx_shift_reg(rx_bit_index) <= rx;
                    rx_bit_index <= rx_bit_index + 1;
                    rx_counter <= 0;
                    
                    if rx_bit_index = 9 then
                        rx_active <= '0';
                        rx_data <= rx_shift_reg(8 downto 1); -- Extract data bits
                        rx_ready <= '1';
                    end if;
                else
                    rx_counter <= rx_counter + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
