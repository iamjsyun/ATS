#==================================================================
# ATSE Scenario: Trailing Entry Exit (v1.0)
# Covers: Trailing Entry Loop -> Exit Injected -> Cancel Trailed Order
#==================================================================

SCENARIO: SCEN_ORD_TRAILING_EXIT_01 : "Trailing Entry Abortion on Exit"
DEFINE: SYMBOL=EURUSD, CNO=1006, SNO=01, GNO=01, DIR=1, TYPE=1

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal with trailing entry options
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1006, yymmddhh=26052704, sno=01, gno=01, dir=1, type=1, te_start=10, te_step=5
TICK: 2   > INJECT: terminal: ticket=77777
          ? EXPECT: session : state=ORD_TRAILING

# Tick 3: Inject exit signal
TICK: 3   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "Failed to abort trailing entry and delete pending order on exit"
