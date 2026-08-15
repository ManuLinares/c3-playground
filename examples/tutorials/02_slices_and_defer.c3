module main;
import std;

fn void heap_example()
{
	io::printn("--- 1. Manual Allocation with 'defer' ---");
	// mem::new_array allocates a zero-initialized array (slice) on the heap.
	// Unlike standard C, this returns a safe, sized slice (int[]) rather than a raw pointer.
	int[] array = mem::new_array(int, 5);

	// 'defer' guarantees memory cleanup at scope exit, preventing leaks without RAII overhead
	defer mem::free(array);

	for (int i = 0; i < array.len; i++)
	{
		array[i] = (i + 1) * 10;
	}

	foreach (idx, val : array) // foreach loops work naturally on slices
	{
		io::printfn("array[%d] = %d", idx, val);
	}
}

fn void temp_example()
{
	io::printn("\n--- 2. Temporary Arena Allocation ---");
	// The @pool macro sets up a temporary allocator scope.
	// All temporary allocations within this block are automatically freed on block exit.
	@pool()
	{
		double[] temp_vals = mem::temp_array(double, 4); // Allocate a temporary double array using the arena allocator
		temp_vals[0] = 3.14;
		temp_vals[1] = 1.61;
		temp_vals[2] = 2.71;
		temp_vals[3] = 1.41;

		double[] sub_slice = temp_vals[1:2]; // Create a sub-slice on the fly using slice syntax [start:length]

		foreach (idx, val : sub_slice)
		{
			io::printfn("sub_slice[%d] = %.2f", idx, val);
		}

		io::printn("Leaving @pool scope... (all temp memory is automatically reclaimed)");
	};
}

fn void main()
{
	heap_example();
	temp_example();
}