#==================================================================
# ATSE Scenario: Position Exit (v1.0)
# Covers: Active Position -> Exit Injected -> Liquidating -> Closed
#==================================================================

SCENARIO: SCEN_POS_ACTIVE_EXIT_01 : "Active Position Liquidation on Exit"
DEFINE: SYMBOL=EURUSD, CNO=1007, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal and activate position
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1007, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
TICK: 2   > INJECT: terminal: order_fill=true, ticket=88888
          ? EXPECT: session : state=POS_ACTIVE

# Tick 3: Inject exit signal, transitioning to POS_LIQUIDATING
TICK: 3   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=POS_LIQUIDATING

# Tick 4: Mock broker position close
TICK: 4   > INJECT: terminal: order_fill=false, ticket=0
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "Failed to close active position on exit"
