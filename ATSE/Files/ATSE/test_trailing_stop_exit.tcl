#==================================================================
# ATSE Scenario: Trailing Stop Exit (v1.0)
# Covers: Trailing Stop Loop -> Exit Injected -> Liquidating
#==================================================================

SCENARIO: SCEN_POS_TRAILING_EXIT_01 : "Trailing Stop Abortion on Exit"
DEFINE: SYMBOL=EURUSD, CNO=1008, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal and activate position
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1008, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, ts_start=10, ts_step=5
TICK: 2   > INJECT: terminal: order_fill=true, ticket=11111

# Tick 3: Price moves up to activate Trailing Stop (1.0950 + 10 points = 1.0960)
TICK: 3   > MARKET: EURUSD  : price=1.0970
          ? EXPECT: session : state=POS_TRAILING

# Tick 4: Inject exit signal, transitioning to POS_LIQUIDATING
TICK: 4   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=POS_LIQUIDATING ! FAIL_MSG: "Failed to abort trailing stop and transition to liquidating"
