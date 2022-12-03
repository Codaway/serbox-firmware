# serbox-firmware
Firmware (Z80 assembler) for "serial interface box" (used in sailboat racing)

I built the "serial interface box" to go between a Brookes&Gatehouse racing sailboat computer
and a masthead-display usually connected to B&G via its serial interface.
When the box is in-between, there is an additional serial channel which can be connected
to a recording device (for recording data I used a "Psion Organizer" specially programmed in OPL).

The box actually has four serial interfaces: one for B&G, one for the masthead display, one for
the Psion Organizer, and a spare one. Inside the box there are two Z80 SIOs, one CTC to provide
timing for the SIOs, a Z80 microprocessor, 4K of ROM, 4K of battery buffered static RAM, and
additional circuitry (5V to +/- 12V boosters for V.24, a signalling LED, clock circuitry, etc.)

The firmware resides in EPROM, but initially copies itself to battery-buffered static RAM, then creates a
checksum and stores that in RAM as well. When the box is rebooted the next time, the checksum is checked and if correct, the
initial copy is skipped. This allows human modifiation of the firmware by patching in code using a "monitor"
program which is also part of the firmware. A human can modify the code, then have the checksum re-computed.

So, there is a "monitor" mode, where a human can configure the serial ports, modify firware code, and recompute
the checksum. I did this, because the box was in a racing sailboat for several weeks when I had no
access to an EPROM programmer, but eventually had to debug and tweak the firmware code.

And there is a "run" mode, where the masthead display sends queries to a serial interface of the box, and
the box sends the query out on the other serial interface to the B&G computer. B&G responds, and the response
is sent back to the masthead display. When the masthead display is not doing queries, B&G transmits other
data, which is then sent to the recording device.
