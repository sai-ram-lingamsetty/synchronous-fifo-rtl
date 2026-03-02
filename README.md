# Synchronous FIFO RTL

## Overview

This project implements a **parameterized, throughput-safe synchronous FIFO** in Verilog.  
The design supports simultaneous read and write operations, full/empty flag generation, and deterministic cycle-accurate behavior.

A **self-checking testbench** is provided to validate:
- Full and empty boundary conditions
- Simultaneous read/write behavior (including zero-latency bypass mode)
- Pointer wrap-around
- Illegal access attempts
- Data integrity across all transactions

---

## Quick Start

### Run Simulation in Vivado 2015.4

#### Option 1: Using Vivado GUI (Recommended)
1. Open Vivado 2015.4
2. Create → New Project (RTL Project)
3. Add Sources:
   - Design: `rtl/sync_fifo.v`
   - Simulation: `tb/sync_fifo_tb.v`
4. Set `sync_fifo_tb` as Top Module (right-click → Set as Top)
5. Tools → Run Simulation → Run Behavioral Simulation
6. Check Tcl Console for: `===== SIMULATION PASSED =====`

---

## Design Parameters

| Parameter | Description | Default | Valid Range |
|-----------|-------------|---------|-------------|
| `WIDTH` | Data bus width (bits per element) | 8 bits | 1 - 256 bits |
| `DEPTH` | Total number of elements | 16 | Power of 2 (8, 16, 32, 64...) |
| `THRESHOLD` | "Almost" flag margin | 2 | 1 to DEPTH-1 |

**Note:** Parameters can be customized when instantiating the module in your design.

---

## Key Features

✅ **Fully synchronous design** - Single clock domain  
✅ **Throughput-safe** - Simultaneous read and write in same cycle  
✅ **Zero-latency bypass** - Direct write-to-read path when FIFO is empty  
✅ **Registered output** - Clean data timing  
✅ **Accurate flags** - `empty`, `full`, `almost_empty`, `almost_full`  
✅ **Self-checking verification** - Comprehensive testbench included  
✅ **Parameter validation** - Runtime checks for valid configurations  
✅ **Vivado compatible** - Works with Vivado 2015.4 and newer versions  

---

## Specifications

| Metric | Value |
|--------|-------|
| **Design Tool** | Xilinx Vivado 2015.4+ |
| **Clock Frequency** | Can be synthesized for any FPGA frequency (100MHz+ typical) |
| **Write Latency** | 1 clock cycle |
| **Read Latency** | 1 clock cycle (registered output) |
| **Bypass Latency** | 0 clock cycles (when FIFO is empty) |
| **Max Throughput** | 1 element per clock cycle |
| **Simulation Status** | ✅ **PASSED** - All test cases verified |

---

## Ports

### Inputs
| Port | Width | Description |
|------|-------|-------------|
| `clk` | 1 bit | Clock signal (rising edge triggered) |
| `rst_n` | 1 bit | Active-low asynchronous reset |
| `wr_en` | 1 bit | Write enable - assert to write data |
| `rd_en` | 1 bit | Read enable - assert to read data |
| `wr_data` | WIDTH | Data input to write into FIFO |

### Outputs
| Port | Width | Description |
|------|-------|-------------|
| `rd_data` | WIDTH | Data output from FIFO |
| `empty` | 1 bit | High when FIFO is empty (no data) |
| `full` | 1 bit | High when FIFO is full (no space) |
| `almost_empty` | 1 bit | High when elements ≤ THRESHOLD |
| `almost_full` | 1 bit | High when free space ≤ THRESHOLD |

---

## Example Instantiation

```verilog
// Example: Create a 32-deep, 16-bit FIFO
sync_fifo #(
    .DEPTH(32),
    .WIDTH(16),
    .THRESHOLD(4)
) my_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full)
);

// Simple usage example
always @* begin
    // Write when data available and FIFO not full
    wr_en = input_valid && !full;
    wr_data = input_data;
    
    // Read when FIFO has data and consumer ready
    rd_en = !empty && output_ready;
    output_data = rd_data;
    
    // Use almost_full flag to signal upstream (optional)
    upstream_backpressure = almost_full;
end
```

---

## Directory Structure

```
synchronous-fifo-rtl/
├── rtl/
│   └── sync_fifo.v              # Main FIFO RTL module
├── tb/
│   └── sync_fifo_tb.v           # Self-checking testbench
├── waveforms/                   # Simulation waveforms
│   ├── README.md                # Waveform descriptions
│   ├── write_burst.png          # Write operation waveform
│   ├── read_burst.png           # Read operation waveform
│   ├── simultaneous_rw.png      # Simultaneous R/W waveform
│   └── bypass.png               # Zero-latency bypass waveform
├── vivado_sim.tcl               # Vivado batch simulation script
├── .gitignore
├── LICENSE
└── README.md                    # This file
```

---

## Simulation & Verification

### Prerequisites
- **Xilinx Vivado 2015.4 or newer**
- Verilog 2005 language support

### Test Coverage

The testbench validates:

#### 1. **Basic Operations**
- Sequential writes (filling the FIFO)
- Sequential reads (emptying the FIFO)
- Simultaneous read and write operations

#### 2. **Boundary Conditions**
- Prevents writing when FIFO is full
- Prevents reading when FIFO is empty
- Correct assertion/deassertion of "almost" flags

#### 3. **Data Integrity**
- Ensures data written comes out in correct order (FIFO behavior)
- Validates pointer wrap-around
- Verifies internal occupancy tracking

#### 4. **Special Features**
- Zero-latency bypass mode (read and write same data in one cycle when empty)
- Flag correctness (FULL and EMPTY never assert simultaneously)

#### 5. **Stress Testing**
- Continuous simultaneous read/write operations
- Rapid state transitions
- Pointer rollover after many cycles

### Run Simulation

**Using Vivado GUI (Easy):**
1. Open your Vivado project
2. Go to: Tools → Run Simulation → Run Behavioral Simulation
3. Wait for simulation to complete
4. Look in Tcl Console output for: `===== SIMULATION PASSED =====`

### Simulation Result
```
===== SIMULATION PASSED =====
```

✅ **Your simulation passed successfully!** All test cases are working correctly.

---

## Vivado Waveform Viewing

### View Waveforms in Vivado
After simulation completes in Vivado GUI:

1. **Waveforms automatically load** in the Wave window
2. **Add signals** to view:
   - Right-click on signal in Scopes panel
   - Select "Add to Wave Window"
3. **Zoom** to see timing details:
   - Scroll or use Zoom In/Out
4. **Export waveforms:**
   - File → Export → Export Waveform

### Key Signals to Monitor
- `clk` - Clock signal
- `wr_en`, `rd_en` - Write and Read enables
- `wr_data`, `rd_data` - Data input/output
- `empty`, `full` - FIFO status flags
- `almost_empty`, `almost_full` - Warning flags

### Detailed Waveform Analysis
See [`waveforms/README.md`](waveforms/README.md) for detailed explanations and timing diagrams showing:
- Write burst behavior
- Read burst behavior  
- Simultaneous read/write timing
- Zero-latency bypass verification

---

## Implementation Details

### How It Works

**Pointer-Based Design:**
- Uses two pointers: `wr_ptr` (write pointer) and `rd_ptr` (read pointer)
- Pointers automatically increment on read/write operations
- Pointers wrap around when they reach DEPTH

**Occupancy Calculation:**
```
Number of elements in FIFO = wr_ptr - rd_ptr
```

**Flag Logic:**
```
EMPTY if occupancy == 0
FULL if occupancy == DEPTH
ALMOST_EMPTY if occupancy <= THRESHOLD (and not empty)
ALMOST_FULL if occupancy >= (DEPTH - THRESHOLD) (and not full)
```

**Simultaneous R/W:**
When reading and writing happen in the same cycle:
```
wr_ptr increments AND rd_ptr increments
Occupancy stays the same
```

**Zero-Latency Bypass:**
When FIFO is empty and you try to read and write simultaneously:
```
Data written goes directly to read output in same cycle
Occupancy remains zero
```

---

## Design Constraints

### Parameter Requirements
⚠️ **DEPTH must be a power of 2** - Valid values: 8, 16, 32, 64, 128, 256...  
⚠️ **THRESHOLD must be less than DEPTH** - For threshold=2, DEPTH must be ≥3  

The design validates these at initialization. If invalid parameters are used, an error message will appear.

---

## Known Limitations

- **Single clock domain only** - Cannot be used across different clock domains
- **Synchronous design only** - Not suitable for asynchronous clock crossing
- **Read/write pointers are internal** - Cannot be directly accessed from outside
- **DEPTH must be power of 2** - Cannot use arbitrary sizes like 10, 20, 50

---

## Troubleshooting

### Simulation Won't Start
- ✅ Check that `sync_fifo_tb` is set as Top Module (right-click file → Set as Top)
- ✅ Make sure both files are in correct filesets:
  - `sync_fifo.v` in "Design Sources"
  - `sync_fifo_tb.v` in "Simulation Sources"
- ✅ Check Tcl Console for error messages

### Waveforms Show Errors
- ✅ Scroll through Tcl Console output
- ✅ Look for lines starting with "ERROR" or "FAILED"
- ✅ Check that simulation ran for enough time

### Signals Look Wrong
- ✅ Make sure reset is applied for first 20 nanoseconds
- ✅ Check clock is toggling properly
- ✅ Verify input signals are changing at expected times

---

## Project Status

✅ **Simulation:** Fully tested and **PASSED**  
✅ **RTL Code:** Ready for synthesis and FPGA implementation  
✅ **Documentation:** Complete with waveform analysis  
✅ **Testbench:** Comprehensive self-checking verification  

---

## What You Can Do Next

1. **Customize the parameters:**
   - Try different DEPTH values (16, 32, 64, 128...)
   - Try different WIDTH values (8, 16, 32, 64...)

2. **Use in your design:**
   - Instantiate the FIFO module in your top-level design
   - Connect to your producer/consumer logic

3. **Extend functionality:**
   - Add write/read pointers as outputs if needed
   - Add occupancy counter output
   - Add programmable threshold

---

## Author

**Sai Ram Lingamsetty**

---

## License

See LICENSE file for details.

---

## Feedback & Contributions

Found an issue? Have a suggestion?
- Open an issue on GitHub
- Submit pull requests for improvements
- Contact: lingamsettysairam@gmail.com | +91 7075488119

---

## Quick Reference

**Default Configuration:**
- WIDTH: 8 bits
- DEPTH: 16 elements
- THRESHOLD: 2

**Clock Frequency:**
- No specific requirement
- Typical: 100MHz (10ns period)

**Verification:**
- ✅ Simulation: PASSED
- ✅ All test cases: VERIFIED
