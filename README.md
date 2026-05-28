# Design Notes – FPGA Systolic Array Accelerator

## Architecture Overview

The accelerator implements a weight-stationary systolic array where:
- Matrix **A** data flows **left → right** across each row of PEs.
- Matrix **B** data flows **top → down** across each column of PEs.
- Each PE accumulates the dot-product contribution for one output element C[i][j].

## Input Skewing

Raw matrix rows/columns cannot be fed simultaneously to all PEs — data must be **diagonally skewed** to ensure that element A[i][k] meets B[k][j] inside PE[i][j] at the same cycle.

Row `i` of matrix A is delayed by `i` cycles before entering the left boundary.  
Column `j` of matrix B is delayed by `j` cycles before entering the top boundary.

## Pipeline Timing

| Parameter | Value |
|-----------|-------|
| Fill latency | (2N − 1) cycles |
| Drain latency | N cycles after last input |
| Throughput (steady-state) | 1 output element / cycle |
| Output valid | After (2N − 1 + N) = (3N − 1) cycles from first input |

## Processing Element (PE)

Each PE is a simple registered MAC:

```
acc <= acc + (A_in * B_in)   [on valid_in]
A_out <= A_in                 [registered, 1-cycle delay]
B_out <= B_in                 [registered, 1-cycle delay]
```

The registered pass-throughs ensure a single flip-flop stage between adjacent PEs, keeping combinational depth at 1 LUT level between registers.

## Parameterization

The entire design is parameterized by:
- `N` — array dimension
- `DATA_WIDTH` — input operand bit-width (default 8-bit)
- `ACCUM_WIDTH` — accumulator bit-width (default 32-bit, avoids overflow for N ≤ 256 with 8-bit inputs)
