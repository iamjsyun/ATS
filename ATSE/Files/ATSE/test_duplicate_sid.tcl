#==================================================================
# ATSE Scenario: Duplicate SID (v1.0)
# Covers: Signal Injection -> Duplicate Signal Injection -> Integrity Maintained
#==================================================================

SCENARIO: SCEN_DUP_INJECT_01 : "Duplicate SID Block"
DEFINE: SYMBOL=EURUSD, CNO=1003, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject first signal
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0950, \
                              cno=1003, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          ? EXPECT: session : state=ORD_READY

# Tick 2: Inject duplicate signal with same parameters but different price
TICK: 2   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0990, \
                              cno=1003, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          ? EXPECT: session : state=ORD_READY ! FAIL_MSG: "Duplicate SID injection corrupted the session"
