#==================================================================
# ATSE Scenario: Void Exit (v1.0)
# Covers: Signal Injected -> Exit Injected (No Asset) -> Immediate Close
#==================================================================

SCENARIO: SCEN_VOID_EXIT_01 : "Void Exit handling (No Terminal Asset)"
DEFINE: SYMBOL=EURUSD, CNO=1004, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal (No physical ticket registered in terminal)
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1004, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          ? EXPECT: session : state=ORD_READY

# Tick 2: Inject exit signal
TICK: 2   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "Void exit failed to close immediately"
