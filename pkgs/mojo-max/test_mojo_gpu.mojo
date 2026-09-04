from max.gpu.host import DeviceContext
from std.sys import has_accelerator
from std.gpu import block_idx, thread_idx

def print_threads():
    """Print thread IDs."""

    print(block_idx.x, thread_idx.x, sep="\t")

def main() raises:
    comptime if not has_accelerator():
        print("No compatible GPU found.")
    else:
        var ctx = DeviceContext()
        print("Found GPU:", ctx.name())
        print("block\tthread")
        ctx.enqueue_function[print_threads](
            grid_dim=2,
            block_dim=64,
        )
        ctx.synchronize()
        print("Program Finished.")
