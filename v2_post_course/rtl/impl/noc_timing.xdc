# Timing constraint for synthesis/implementation timing runs (noc_top as top module).
# Only the clock is constrained: internal register-to-register paths are analyzed;
# top-level I/O paths stay unconstrained on purpose (they only exist because the
# design is synthesized out-of-context, and would otherwise dominate the report).
create_clock -period 8.000 -name clk [get_ports clk]
# 10.000 ns = 100 MHz. To find the limit, rerun at 8.0 (125 MHz), 6.67 (150 MHz), 5.0 (200 MHz).
