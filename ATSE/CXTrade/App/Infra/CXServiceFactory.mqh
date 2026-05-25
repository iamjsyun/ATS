#ifndef CXSERVICEFACTORY_MQH
#define CXSERVICEFACTORY_MQH
#include "..\..\Core\Interfaces\ICXServiceFactory.mqh"
#include "..\..\Session\CXContext.mqh"
#include "..\..\Shared\Logging\CXLogDispatcher.mqh"
#include "..\..\Shared\Logging\CXFileLogger.mqh"
#include "..\..\Shared\Logging\CXFileLoggerSID.mqh"
#include "..\..\Shared\Logging\CXTabLogger.mqh"
#include "..\..\Shared\Logging\CXRemoteLogger.mqh"
#include "..\..\Session\Sequence\CXFluentSequence.mqh"
#include "..\..\Shared\Database\CXDatabase.mqh"
#include "..\..\Shared\Database\CXSignalRepository.mqh"

#include "..\..\Execution\Order\CXEntryManager.mqh"
#include "..\..\Execution\Order\CXOrderManager.mqh"
#include "..\..\Execution\Position\CXPositionManager.mqh"
#include "..\..\Execution\Exit\CXExitManager.mqh"

#include "..\..\Engine\Price\CXPriceTracker.mqh"
#include "..\..\Engine\Price\CXPriceManager.mqh"
#include "..\..\Engine\Risk\CXRiskManager.mqh"
#include "..\..\Engine\Symbol\CXSymbolManager.mqh"
#include "..\..\Engine\Inventory\CXInventoryManager.mqh"
#include "..\..\Session\CXContext.mqh"

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
                bool initOnStart = config.IsLogInitOnStart(category);
                if(category == "Session") {
                    CXFileLoggerSID* fileLog = new CXFileLoggerSID();
                    if(IS_VALID(fileLog) && fileLog.Init(sid, initOnStart)) {
                        logger.SetFileLogger(fileLog);
                    } else {
                        SAFE_DELETE(fileLog);
                    }
                } else {
                    CXFileLogger* fileLog = new CXFileLogger();
                    if(IS_VALID(fileLog) && fileLog.Init(sid, initOnStart)) {
                        logger.SetFileLogger(fileLog);
                    } else {
                        SAFE_DELETE(fileLog);
                    }
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

    virtual IDatabase* CreateDatabase() override {
        return new CXDatabase();
    }

    virtual IRepository* CreateRepository(IDatabase* db) override {
        return new CXSignalRepository(db);
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
