// PROVOLONE


// Includes
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <stdlib.h>


// Ports for the serial shift registers
on stdcore[0]: out port p_latch = XS1_PORT_1A;
on stdcore[0]: out port p_clk = XS1_PORT_1B;
on stdcore[0]: out port p_mosi = XS1_PORT_1C;
on stdcore[0]: in port p_miso = XS1_PORT_1D;


// Run the clock at 1MHz (2 x 0.5us delays (50 reference clock tick))
#define DELAY 50


// Thread to reflect the data send to it, to loop back the threads and buttons.
void test_reflector ( chanend c_leds, chanend c_buttons )
{
	char my_data;

	// Loop forever
	while ( 1 )
	{
		// Get the value for the buttons
		c_buttons :> my_data;

		// Send it out to the LEDs
		c_leds <: my_data;
	}
}


// Test thread to interface with LEDs and buttons
void test_leds_buttons ( chanend c_leds, chanend c_buttons )
{
	char 			led_val = 0, button_val, tmp_but;
	unsigned int	i, time, loop_time;
	timer 			t;

	// Get the initial timer value
	t :> loop_time;

	// Setup the initial output values
	p_latch <: 1;
	p_clk <: 0;
	p_mosi <: 0;

	// Loop forever
	while ( 1 )
	{
		select
		{
			// Receive a new value for the LEDs over a channel
			case c_leds :> led_val:
				break;

			// At 100Hz sample the buttons and output the value to the LEDs
			case t when timerafter(loop_time + 100000) :> loop_time:

				// Copy over the loop_time value, so the timing can use it
				time = loop_time;

				// Initialise the button value.
				button_val = 0;

				// Place a rising edge on the latch signal
				// This clocks the previously loaded LED data out and captures the button data
				p_latch <: 0;
				t when timerafter(time + DELAY) :> time;
				p_latch <: 1;
				t when timerafter(time + DELAY) :> time;

				// Cycle through 8 bits
				for ( i = 0; i < 8; i++ )
				{
					// Output the data, MSB bit first.
					p_mosi <: (char) (led_val >> i);

					// Wait for half a bit time
					t when timerafter(time + DELAY) :> time;

					// Set the clock high
					p_clk <: 1;

					// Get the current bit from the shift register
					p_miso :> tmp_but;

					// Add the bit to the button value, LSB bit first.
					button_val = button_val + (tmp_but << i);

					// Wait for half a bit time
					t when timerafter(time + DELAY) :> time;

					// Set the clock low
					p_clk <: 0;
				}

				// Send the button value out
				c_buttons <: button_val;

				break;
		}
	}
}


// Program entry point
int main()
{
	chan c_leds, c_buttons;

	par
	{
		// XCore 0
		on stdcore[0] :	test_reflector( c_leds, c_buttons );
		on stdcore[0] :	test_leds_buttons( c_leds, c_buttons );
	}

	return 0;
}
