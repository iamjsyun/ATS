#==================================================================
# ATSE E2E Golden Path Test Scenario (v1.0)
# Covers: Entry -> Trailing Entry -> Execution -> Trailing Stop -> SL Close
#==================================================================

SCENARIO: SCEN_GOLDEN_PATH_01 : "Golden Path E2E Test (Entry -> Trailing -> Active -> Trailing Stop -> SL)"
DEFINE: SYMBOL=EURUSD, CNO=1001, SNO=01, GNO=01, DIR=1, TYPE=1, LOT=0.1

# Pricer setup starting at 1.0950 with 2 points spread
PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal and verify session creation
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0950, \
                              cno=1001, yymmddhh=26052704, sno=01, gno=01, dir=1, type=1, \
                              lot=0.1, te_start=10, te_step=5, te_limit=50, \
                              ts_start=15, ts_step=5, sl=100, tp=150
          ? EXPECT: session : state=ORD_READY * xe_status=XE_READY ! FAIL_MSG: "Failed to initialize signal or session"

# Tick 2: Mock pending order ticket placement on broker
TICK: 2   > INJECT: terminal: order_fill=false, ticket=12345
          ? EXPECT: session : state=ORD_TRAILING * xe_status=XE_PENDING_PLACED ! FAIL_MSG: "Failed to place pending order and transition to trailing"

# Tick 3: Price moves down (tracks Buy Limit order)
TICK: 3   > MARKET: EURUSD  : price=1.0940
          ? EXPECT: session : state=ORD_TRAILING * xe_status=XE_PENDING_PLACED

# Tick 4: Mock position execution (fill the pending order)
TICK: 4   > INJECT: terminal: order_fill=true, ticket=12345
          ? EXPECT: session : state=POS_ACTIVE * xe_status=XE_EXECUTED ! FAIL_MSG: "Failed to execute order fill"

# Tick 5: Price moves up to activate Trailing Stop (1.0940 + 15 points = 1.0955)
TICK: 5   > MARKET: EURUSD  : price=1.0960
          ? EXPECT: session : state=POS_TRAILING * xe_status=XE_EXECUTED ! FAIL_MSG: "Failed to activate trailing stop"

# Tick 6: Price drops below SL, and terminal position is closed (SL hit simulation)
TICK: 6   > MARKET: EURUSD  : price=1.0930
          > INJECT: terminal: order_fill=false, ticket=0
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SL ! FAIL_MSG: "Failed to capture SL triggered close"
