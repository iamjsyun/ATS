//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef CXSIGNALREPOSITORY_MQH
#define CXSIGNALREPOSITORY_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\IDatabase.mqh"
#include "..\Models\CXSignal.mqh"

class CXSignalRepository : public IRepository {
private:
   IDatabase* m_db;
   
   //--- 고정 쿼리 핸들 캐싱 (Performance Optimization)
   int        m_hActiveSignals;
   int        m_hSignalBySid;

   int GetColumnIndex(int req, string name) {
      int count = DatabaseColumnsCount(req);
      string name_upper = name;
      StringToUpper(name_upper);
      
      for(int i = 0; i < count; i++) {
         string col_name;
         if(DatabaseColumnName(req, i, col_name)) {
            string col_upper = col_name;
            StringToUpper(col_upper);
            if(col_upper == name_upper) return i;
         }
      }
      // Print("Column " + name + " not found!");
      return -1;
   }

public:
   CXSignalRepository(IDatabase* db) : m_db(db), 
      m_hActiveSignals(INVALID_HANDLE), 
      m_hSignalBySid(INVALID_HANDLE) {}

   virtual ~CXSignalRepository() {
      if(m_hActiveSignals != INVALID_HANDLE) DatabaseFinalize(m_hActiveSignals);
      if(m_hSignalBySid != INVALID_HANDLE)  DatabaseFinalize(m_hSignalBySid);
   }

   virtual void SaveSignal(ICXSignal* signal) override {
      if(IS_INVALID(signal) || IS_INVALID(m_db)) return;

      //--- SSOT 46개 필드 기반 저장 (DML)
      string sql = StringFormat(
                      "INSERT OR REPLACE INTO signals ("
                      "sid, gid, cno, sno, msg_id, raw_id, xa_entry, xa_exit, xe_status, xe_status_msg, "
                      "time, symbol, dir, type, price_signal, offset, step, te_start, te_step, te_limit, te_interval, "
                      "ikte_start, ikte_step, tp, sl, ts_start, ts_step, close_type, trail_price, "
                      "price_limit, price, price_open, price_close, price_tp, price_sl, lot, ticket, magic, "
                      "comment, tag, created, updated, limit_offset, stop_offset"
                      ") VALUES ("
                      "'%s', '%s', %d, %d, %d, %d, %d, %d, %d, '%s', "
                      "'%s', '%s', %d, %d, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %d, "
                      "%.5f, %.5f, %.5f, %.5f, %d, %d, %d, %.5f, "
                      "%.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.2f, %lld, %lld, "
                      "'%s', '%s', datetime('%s'), datetime('now','localtime'), %.5f, %.5f"
                      ")",
                      signal.GetSid(), signal.GetGid(), signal.GetCno(), signal.GetSno(), signal.GetMsgId(), signal.GetRawId(),
                      signal.GetXAEntry(), signal.GetXAExit(), signal.GetStatus(), signal.GetStatusMsg(),
                      signal.GetTime(), signal.GetSymbol(), signal.GetDir(), signal.GetType(), signal.GetPriceSignal(), signal.GetOffset(), signal.GetStep(),
                      signal.GetTEStart(), signal.GetTEStep(), signal.GetTELimit(), signal.GetTEInterval(),
                      signal.GetIkTeStart(), signal.GetIkTeStep(), signal.GetTP(), signal.GetSL(), signal.GetTSStart(), signal.GetTSStep(),
                      signal.GetCloseType(), signal.GetTrailPrice(), signal.GetPriceLimit(), signal.GetPrice(),
                      signal.GetPriceOpen(), signal.GetPriceClose(), signal.GetPriceTP(), signal.GetPriceSL(),
                      signal.GetLot(), signal.GetTicket(), signal.GetMagic(), signal.GetComment(), signal.GetTag(),
                      TimeToString(signal.GetCreated(), TIME_DATE|TIME_SECONDS), signal.GetLimitOffset(), signal.GetStopOffset()
                   );
      m_db.Execute(sql);
   }

   virtual void LoadParam(ICXParam* param) override {
      // Implementation for loading dynamic parameters
   }

   virtual int GetStatusBySid(const string sid) override {
      if(IS_INVALID(m_db) || sid == "") return -1;
      string sql = StringFormat("SELECT xe_status FROM signals WHERE sid='%s'", sid);
      int handle = m_db.GetHandle();
      int req = DatabasePrepare(handle, sql);
      int status = -1;
      if(req != INVALID_HANDLE) {
         if(DatabaseRead(req)) DatabaseColumnInteger(req, 0, status);
         DatabaseFinalize(req);
      }
      return status;
   }

   virtual bool UpdateStatus(ICXSignal* signal) override {
      if(IS_INVALID(m_db) || IS_INVALID(signal)) return false;
      string sql = StringFormat(
                      "UPDATE signals SET xe_status=%d, xe_status_msg='%s', updated=datetime('now','localtime') WHERE sid='%s'",
                      signal.GetStatus(), signal.GetStatusMsg(), signal.GetSid()
                   );
      return m_db.Execute(sql);
   }
virtual int LoadActiveSignals(CArrayObj* list) override {
   if (IS_INVALID(m_db) || IS_INVALID(list)) return 0;

   //-- [v10.9.1 Diagnostic] Experts 탭 + 시스템 로그 동시 출력
   //-- 1. DB 파일 내 전체 레코드 수 확인
   int total = 0;
   int hTotal = DatabasePrepare(m_db.GetHandle(), "SELECT count(*) FROM signals");
   if(hTotal != INVALID_HANDLE) {
      if(DatabaseRead(hTotal)) DatabaseColumnInteger(hTotal, 0, total);
      DatabaseFinalize(hTotal);
   }

   //-- 2. 필터링 쿼리 실행 (v10.22: Exclude XE_ERROR(99) to prevent zombie sessions)
   string sql = StringFormat("SELECT * FROM signals WHERE (xa_entry > %d AND xe_status < %d AND xe_status <> %d)", 
                             XA_RAW, XE_CLOSED_SIGNAL, XE_ERROR);

   int hQuery = DatabasePrepare(m_db.GetHandle(), sql);
   if(hQuery == INVALID_HANDLE) {
      PrintFormat("[REPO-ERROR] DatabasePrepare Failed. SQL:%s, Error:%d", sql, _LastError);
      return 0;
   }

   int count = FetchSignals(hQuery, list);
   DatabaseFinalize(hQuery);

   //-- 3. [Diagnostic Output] 전문가 탭 + 시스템 로그 동시 기록 (v10.19.1 XP_LOG 통합)
   if(count == 0) {
      string diagMsg = StringFormat("[REPO-DIAG] Discovery: 0 found (Total in DB: %d). SQL: %s", total, sql);
      
      //-- [v10.17] 중복 출력 방지 로직이 적용된 XP_LOG 시스템으로 리다이렉션
      //-- XP_LOG_TRACE는 level < ERROR 이므로 자동 중복 제거 대상임
      XP_LOG_TRACE(NULL, diagMsg); 
   }

   return count;
}   virtual ICXSignal* GetSignalBySid(const string sid) override {
      if (IS_INVALID(m_db) || sid == "") return NULL;

      //-- 2. 파라미터 바인딩 기반 핸들 캐싱
      if(m_hSignalBySid == INVALID_HANDLE) {
         string sql = "SELECT * FROM signals WHERE sid = ?";
         m_hSignalBySid = DatabasePrepare(m_db.GetHandle(), sql);
         if(m_hSignalBySid == INVALID_HANDLE) return NULL;
      } else {
         DatabaseReset(m_hSignalBySid);
      }

      //-- 3. 파라미터 바인딩 및 실행
      DatabaseBind(m_hSignalBySid, 0, sid);
      
      CArrayObj list;
      if (FetchSignals(m_hSignalBySid, GetPointer(list)) > 0) {
         return CX_CAST(ICXSignal, list.Detach(0));
      }
      return NULL;
   }

private:
   int FetchSignals(int req, CArrayObj* list) {
      int count = 0;
      int idx = -1;
      while (DatabaseRead(req)) {
         CXSignal* sig = new CXSignal();

         if((idx = GetColumnIndex(req, "id")) >= 0)           DatabaseColumnInteger(req, idx, sig.id);
         if((idx = GetColumnIndex(req, "sid")) >= 0)          DatabaseColumnText(req,    idx, sig.sid);
         if((idx = GetColumnIndex(req, "gid")) >= 0)          DatabaseColumnText(req,    idx, sig.gid);
         if((idx = GetColumnIndex(req, "cno")) >= 0)          DatabaseColumnInteger(req, idx, sig.cno);
         if((idx = GetColumnIndex(req, "sno")) >= 0)          DatabaseColumnInteger(req, idx, sig.sno);
         if((idx = GetColumnIndex(req, "msg_id")) >= 0)       DatabaseColumnInteger(req, idx, sig.msg_id);
         if((idx = GetColumnIndex(req, "raw_id")) >= 0)       DatabaseColumnInteger(req, idx, sig.raw_id);
         if((idx = GetColumnIndex(req, "xa_entry")) >= 0)     DatabaseColumnInteger(req, idx, sig.xa_entry);
         if((idx = GetColumnIndex(req, "xa_exit")) >= 0)      DatabaseColumnInteger(req, idx, sig.xa_exit);
         if((idx = GetColumnIndex(req, "xe_status")) >= 0)    DatabaseColumnInteger(req, idx, sig.xe_status);
         if((idx = GetColumnIndex(req, "xe_status_msg")) >= 0) DatabaseColumnText(req,   idx, sig.xe_status_msg);
         if((idx = GetColumnIndex(req, "time")) >= 0)         DatabaseColumnText(req,    idx, sig.time);
         if((idx = GetColumnIndex(req, "symbol")) >= 0)       DatabaseColumnText(req,    idx, sig.symbol);
         if((idx = GetColumnIndex(req, "dir")) >= 0)          DatabaseColumnInteger(req, idx, sig.dir);
         if((idx = GetColumnIndex(req, "type")) >= 0)         DatabaseColumnInteger(req, idx, sig.type);
         if((idx = GetColumnIndex(req, "price_signal")) >= 0) DatabaseColumnDouble(req,  idx, sig.price_signal);

         //-- [v10.23 Schema Align] 'offset'/'step' removed (not in DB), using limit/stop_offset instead
         if((idx = GetColumnIndex(req, "te_start")) >= 0)     DatabaseColumnDouble(req,  idx, sig.te_start);
         if((idx = GetColumnIndex(req, "te_step")) >= 0)      DatabaseColumnDouble(req,  idx, sig.te_step);
         if((idx = GetColumnIndex(req, "te_limit")) >= 0)     DatabaseColumnDouble(req,  idx, sig.te_limit);
         if((idx = GetColumnIndex(req, "te_interval")) >= 0)  DatabaseColumnInteger(req, idx, sig.te_interval);
         if((idx = GetColumnIndex(req, "ikte_start")) >= 0)    DatabaseColumnDouble(req,  idx, sig.ikte_start);
         if((idx = GetColumnIndex(req, "ikte_step")) >= 0)     DatabaseColumnDouble(req,  idx, sig.ikte_step);
         if((idx = GetColumnIndex(req, "tp")) >= 0)           DatabaseColumnDouble(req,  idx, sig.tp);
         if((idx = GetColumnIndex(req, "sl")) >= 0)           DatabaseColumnDouble(req,  idx, sig.sl);
         if((idx = GetColumnIndex(req, "ts_start")) >= 0)     DatabaseColumnInteger(req, idx, sig.ts_start);
         if((idx = GetColumnIndex(req, "ts_step")) >= 0)      DatabaseColumnInteger(req, idx, sig.ts_step);
         if((idx = GetColumnIndex(req, "close_type")) >= 0)   DatabaseColumnInteger(req, idx, sig.close_type);
         if((idx = GetColumnIndex(req, "trail_price")) >= 0)  DatabaseColumnDouble(req,  idx, sig.trail_price);
         if((idx = GetColumnIndex(req, "price_limit")) >= 0)  DatabaseColumnDouble(req,  idx, sig.price_limit);
         if((idx = GetColumnIndex(req, "price")) >= 0)        DatabaseColumnDouble(req,  idx, sig.price);
         if((idx = GetColumnIndex(req, "price_open")) >= 0)   DatabaseColumnDouble(req,  idx, sig.price_open);
         if((idx = GetColumnIndex(req, "price_close")) >= 0)  DatabaseColumnDouble(req,  idx, sig.price_close);
         if((idx = GetColumnIndex(req, "price_tp")) >= 0)     DatabaseColumnDouble(req,  idx, sig.price_tp);
         if((idx = GetColumnIndex(req, "price_sl")) >= 0)     DatabaseColumnDouble(req,  idx, sig.price_sl);
         if((idx = GetColumnIndex(req, "lot")) >= 0)          DatabaseColumnDouble(req,  idx, sig.lot);
         if((idx = GetColumnIndex(req, "ticket")) >= 0)       DatabaseColumnLong(req,    idx, sig.ticket);
         if((idx = GetColumnIndex(req, "magic")) >= 0)        DatabaseColumnLong(req,    idx, sig.magic);
         if((idx = GetColumnIndex(req, "comment")) >= 0)      DatabaseColumnText(req,    idx, sig.comment);
         if((idx = GetColumnIndex(req, "tag")) >= 0)          DatabaseColumnText(req,    idx, sig.tag);
         
         string created_str;
         if((idx = GetColumnIndex(req, "created")) >= 0 && DatabaseColumnText(req, idx, created_str))
            sig.created = StringToTime(created_str);
            
         string updated_str;
         if((idx = GetColumnIndex(req, "updated")) >= 0 && DatabaseColumnText(req, idx, updated_str))
            sig.updated = StringToTime(updated_str);
            
         if((idx = GetColumnIndex(req, "limit_offset")) >= 0) DatabaseColumnDouble(req, idx, sig.limit_offset);
         if((idx = GetColumnIndex(req, "stop_offset")) >= 0)  DatabaseColumnDouble(req, idx, sig.stop_offset);

         list.Add(sig);
         count++;
      }
      return count;
   }
};

#endif
