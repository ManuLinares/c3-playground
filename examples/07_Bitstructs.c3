module main;
import std;

// Bitstructs map fields into a specific backing integer layout
bitstruct CpuStatus : ushort
{
	bool carry : 0;
	bool zero : 1;
	bool interrupt : 2;
	uint reserved : 3..7;
	uint mode : 8..11;
}

fn int main()
{
	// Designated initialization
	CpuStatus status = { .carry = true, .zero = false, .interrupt = true, .reserved = 15, .mode = 9 };

	io::printn("--- 1. Reading Bitstruct Fields ---");
	io::printfn("Carry Flag:     %s", status.carry);
	io::printfn("Zero Flag:      %s", status.zero);
	io::printfn("Interrupt Flag: %s", status.interrupt);
	io::printfn("Reserved Bits:  %d", status.reserved);
	io::printfn("Processor Mode: %d", status.mode);

	io::printn("\n--- 2. Casting & Inspecting Backing Type ---");
	ushort raw_value = (ushort)status;
	io::printfn("Raw ushort (Hex):     0x%04X (Decimal: %d)", raw_value, raw_value);

	// C3 natively supports binary formatting via %b (including zero-padding like %016b)
	io::printfn("Raw ushort (Binary):  %016b", raw_value);
	io::printn("                      Mode Resrvd Flags");

	io::printn("\n--- 3. Mutating Fields ---");
	status.carry = false;
	status.mode = 12;

	ushort mutated_value = (ushort)status;
	io::printfn("New ushort (Hex):     0x%04X", mutated_value);
	io::printfn("New ushort (Binary):  %016b", mutated_value);

	return 0;
}
