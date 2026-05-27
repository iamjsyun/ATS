#==================================================================
# ATSE Scenario: Zombie Recovery (v1.0)
# Covers: Orphan Asset -> Reverse Injection -> Quarantined
#==================================================================

SCENARIO: SCEN_ZOMBIE_RECOVERY_01 : "Zombie Asset Recovery and Quarantine"
DEFINE: SYMBOL=EURUSD, CNO=1002, SNO=01, GNO=01, DIR=1, TYPE=0

PRICER: EURUSD > TREND : trend_slope=0.0, jump_prob=0.0, start=1.0950, spread=2

# Tick 1: Inject position in terminal directly (simulating zombie position)
TICK: 1   > INJECT: terminal: order_fill=true, ticket=99999
          # Expect reverse injection to trigger and place the session in quarantined state
          ? EXPECT: session : state=POS_ACTIVE * xe_status=XE_QUARANTINED ! FAIL_MSG: "Zombie asset quarantine failed"
