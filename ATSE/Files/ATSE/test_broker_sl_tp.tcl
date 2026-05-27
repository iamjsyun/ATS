#==================================================================
# ATSE Scenario: Broker SL/TP close (v1.0)
# Covers: Active Position -> Price moves past SL -> Broker SL Trigger -> Closed SL
#==================================================================

SCENARIO: SCEN_BROKER_SL_TP_01 : "Broker SL Triggered Close"
DEFINE: SYMBOL=EURUSD, CNO=1009, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject signal with SL (50 points) and TP (100 points)
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1009, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, \
                              sl=50, tp=100, price_signal=1.0950
TICK: 2   > INJECT: terminal: order_fill=true, ticket=22222
          ? EXPECT: session : state=POS_ACTIVE

# Tick 3: Price moves down (1.0940). This crosses the SL price (1.0945).
# The mock broker triggers SL close, and the engine detects it.
TICK: 3   > MARKET: EURUSD  : price=1.0940
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SL ! FAIL_MSG: "Failed to detect SL hit and close session with XE_CLOSED_SL"
