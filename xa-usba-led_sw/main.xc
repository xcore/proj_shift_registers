// Includes
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <stdlib.h>


// Ports for the serial shift registers
on stdcore[1]: out port p_led = XS1_PORT_4F;
on stdcore[1]: clock my_clk = XS1_CLKBLK_1;
// 0 = SER_IN
// 1 = CLK
// 2 = RCK
// 3 = OE_N


// Defines for the LED panels
#define NUM_PANELS 7
#define NUM_COLUMNS_PER_PANEL 6
#define TOTAL_COLUMNS (NUM_PANELS * NUM_COLUMNS_PER_PANEL)


// Test thread to interface with LEDs
void test_leds ( void )
{
	char 			led_val[TOTAL_COLUMNS], temp = 0;
	signed int		panel, column, row;
	unsigned int	i, loop_time, my_row = 0;
	timer 			t;

	// Configure the output to run from a clk blk at 10MHz clock rate
	set_clock_div(my_clk,2);
	configure_out_port(p_led,my_clk,0);
	start_clock(my_clk);

	// Get the initial timer value
	t :> loop_time;

	// Setup the initial output values
	p_led <: 0;

	// Wipe the led_vals
	for ( i = 0; i < TOTAL_COLUMNS; i++ )
	{
		led_val[i] = 0x00;
	}

	// Loop forever
	while ( 1 )
	{
		select
		{
			// At 10Hz update and output the value to the LEDs
			case t when timerafter(loop_time + 10000000) :> loop_time:

				// Loop though all the panels (boards)
				for ( panel = 0; panel < NUM_PANELS; panel++ )
				{
					// Loop though the 6 columns
					for ( column = 5; column > -1; column-- )
					{
						// Loop through each row of the column of 8 bits
						for ( row = 7; row > -1; row-- )
						{
							// Get the required bit of the LED data, MSB bit first.
							temp = (led_val[(panel * 6) + column] >> row) & 0x1;

							// Place the data onto the port and set the clock high
							p_led <: (temp + 2);

							// Set the clock low
							p_led <: temp;
						}
					}
				}

				// Clock the data into the output registers
				p_led <: 4;

				// Set the current row to 0
				led_val[my_row++] = 0x00;

				// Prevent my_row from oerflowing out of led_val
				if (my_row == TOTAL_COLUMNS)
				{
					my_row = 0;
				}

				// Set the next row to 1
				led_val[my_row] = 0xFF;

				break;
		}
	}
}


// Program entry point
int main()
{
	par
	{
		// XCore 1
		on stdcore[1] :	test_leds( );
	}

	return 0;
}
