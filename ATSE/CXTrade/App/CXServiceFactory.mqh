#ifndef CXSERVICEFACTORY_MQH
#define CXSERVICEFACTORY_MQH

#include "..\Interfaces\ICXServiceFactory.mqh"
#include "..\Models\CXContext.mqh"
#include "..\Module\CXLogDispatcher.mqh"
#include "..\Infra\CXFileLogger.mqh"
#include "..\Infra\CXTabLogger.mqh"
#include "..\Infra\CXRemoteLogger.mqh"
#include "..\Infra\CXFluentSequence.mqh"

#include "..\Session\Execution\CXEntryManager.mqh"
#include "..\Session\Execution\CXOrderManager.mqh"
#include "..\Session\Execution\CXPositionManager.mqh"
#include "..\Session\Execution\CXExitManager.mqh"
#include "..\Module\Alpha\CXPriceTracker.mqh"
#include "..\Infra\CXPriceManager.mqh"
#include "..\Infra\CXRiskManager.mqh"
#include "..\Infra\CXSymbolManager.mqh"
#include "..\Infra\CXInventoryManager.mqh"

/**
 * @class CXServiceFactory
 * @brief 구상 클래스의 인스턴스화를 전담하는 팩토리 클래스
 */
class CXServiceFactory : public ICXServiceFactory {
public:
    CXServiceFactory() {}
    virtual ~CXServiceFactory() {}

    virtual ICXContext* CreateContext() override {
        return new CXContext();
    }

    virtual ICXLogger* CreateLogger(string sid, ICXConfig* config) override {
        CXLogDispatcher* logger = new CXLogDispatcher();
        if(IS_INVALID(logger)) return NULL;
        logger.SetConfig(config);

        //-- [v10.0] Granular Control & Filtering
        string category = "Session";
        if(sid == "Watcher" || sid == "SignalWatcher") category = "Watcher";
        else if(sid == "System") category = "System";

        if(IS_VALID(config)) {
            // 1. CNO Filtering (For Sessions)
            if(category == "Session") {
                string parts[];
                if(StringSplit(sid, '-', parts) > 0) {
                    long cno = StringToInteger(parts[0]);
                    if(!config.IsCnoLogEnabled(cno)) {
                        return logger; // Return dispatcher with no channels (Empty Logger)
                    }
                }
            }

            // 2. File Logger (Pair)
            if(config.IsFileLogEnabled(category)) {
                CXFileLogger* fileLog = new CXFileLogger();
                if(IS_VALID(fileLog) && fileLog.Init(sid, config.IsLogInitOnStart(category))) {
                    logger.SetFileLogger(fileLog);
                } else {
                    SAFE_DELETE(fileLog);
                }
            }

            //-- [v10.13 Restoration] Terminal Experts Tab Logger
            logger.SetTabLogger(new CXTabLogger());

            // 3. Remote Logger (Pair)
            if(config.IsRemoteLogEnabled(category)) {
                string host = config.GetRemoteLogHost();
                int port = config.GetRemoteLogPort();
                if(host != "" && port > 0) {
                    logger.SetRemoteLogger(new CXRemoteLogger(sid, host, port, logger.GetFileLogger()));
                }
            }

            // 4. UI Logger
            if(config.IsUILogEnabled(category)) {
                // UI Logger implementation mapping here if separate
            }
        }
        
        return logger;
    }

    virtual ICXFluentSequence* CreateSequence(ICXContext* ctx, string name) override {
        return new CXFluentSequence(ctx, name);
    }

    virtual IXEntryManager* CreateEntryManager(ICXContext* ctx) override {
        return new CXEntryManager(ctx);
    }
    
    virtual IXOrderManager* CreateOrderManager(ICXContext* ctx) override {
        return new CXOrderManager(ctx);
    }
    
    virtual IXPositionManager* CreatePositionManager(ICXContext* ctx) override {
        return new CXPositionManager(ctx);
    }
    
    virtual IXExitManager* CreateExitManager(ICXContext* ctx) override {
        return new CXExitManager(ctx);
    }
    
    virtual IXPriceTracker* CreatePriceTracker(ICXContext* ctx) override {
        return new CXPriceTracker();
    }

    virtual ICXPriceManager* CreatePriceManager(ICXContext* ctx) override {
        return new CXPriceManager(ctx);
    }

    virtual ICXRiskManager* CreateRiskManager(ICXContext* ctx) override {
        return new CXRiskManager(ctx);
    }

    virtual ICXSymbolManager* CreateSymbolManager(ICXContext* ctx) override {
        return new CXSymbolManager();
    }

    virtual ICXInventoryManager* CreateInventoryManager(ICXContext* ctx) override {
        return new CXInventoryManager();
    }
};

#endif
