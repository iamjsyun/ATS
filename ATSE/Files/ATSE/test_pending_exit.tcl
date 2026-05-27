#==================================================================
# ATSE Scenario: Pending Exit (v1.0)
# Covers: Limit Signal -> Exit Injected (In Ready/Pending) -> Cancel Order
#==================================================================

SCENARIO: SCEN_ORD_READY_EXIT_01 : "Pending Order Cancellation on Exit"
DEFINE: SYMBOL=EURUSD, CNO=1005, SNO=01, GNO=01, DIR=1, TYPE=1

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject Limit signal and verify ready state
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1005, yymmddhh=26052704, sno=01, gno=01, dir=1, type=1
          ? EXPECT: session : state=ORD_READY

# Tick 2: Inject exit signal before order is filled
TICK: 2   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "Failed to immediately cancel pending order on exit"
