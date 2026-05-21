#ifndef CXSIGNAL_MQH
#define CXSIGNAL_MQH

#include "..\Interfaces\ICXSignal.mqh"
#include "..\Interfaces\CXDefine.mqh"

/**
 * @class CXSignal
 * @brief 시스템 전반에서 사용되는 신호 엔티티 (spec.md 2.3 SSOT 준수)
 */
class CXSignal : public ICXSignal {
public:
    int       id;
    string    sid;
    string    gid;
    int       cno;
    int       sno;
    int       msg_id;
    int       raw_id;
    int       xa_entry;
    int       xa_exit;
    int       xe_status;
    string    xe_status_msg;
    string    time;
    string    symbol;
    int       dir;
    int       type;
    double    price_signal;
    double    offset;
    double    step;
    double    te_start;
    double    te_step;
    double    te_limit;
    int       te_interval;
    double    ikte_start;
    double    ikte_step;
    double    tp;
    double    sl;
    int       ts_start;
    int       ts_step;
    int       close_type;
    double    trail_price;
    double    price_limit;
    double    price;
    double    price_open;
    double    price_close;
    double    price_tp;
    double    price_sl;
    double    lot;
    long      ticket;
    long      magic;
    string    comment;
    string    tag;
    datetime  created;
    datetime  updated;
    double    limit_offset;
    double    stop_offset;
    int       last_status; //-- [v11.0]

    CXSignal() : id(0), sid(""), gid(""), cno(0), sno(0), msg_id(0), raw_id(0),
                 xa_entry(0), xa_exit(0), xe_status(0), xe_status_msg(""), time(""),
                 symbol(""), dir(0), type(0), price_signal(0), offset(0), step(0),
                 te_start(0), te_step(0), te_limit(0), te_interval(0), 
                 ikte_start(0), ikte_step(0), tp(0), sl(0),
                 ts_start(0), ts_step(0), close_type(0), trail_price(0), 
                 price_limit(0), price(0), price_open(0), price_close(0), 
                 price_tp(0), price_sl(0), lot(0), ticket(0), magic(0), 
                 comment(""), tag(""), created(0), updated(0), 
                 limit_offset(0), stop_offset(0), last_status(-1) {}

    virtual ~CXSignal() override {}

    //--- 속성 접근자 구현
    virtual int       GetId() const override { return id; }
    virtual string    GetSid() const override { return sid; }
    virtual string    GetGid() const override { return gid; }
    virtual int       GetCno() const override { return cno; }
    virtual int       GetSno() const override { return sno; }
    virtual int       GetMsgId() const override { return msg_id; }
    virtual int       GetRawId() const override { return raw_id; }

    virtual int       GetXAEntry() const override { return xa_entry; }
    virtual int       GetXAExit() const override { return xa_exit; }
    virtual int       GetStatus() const override { return xe_status; }
    virtual void      SetStatus(int status) override { xe_status = status; }
    virtual string    GetStatusMsg() const override { return xe_status_msg; }
    virtual void      SetStatusMsg(string msg) override { xe_status_msg = msg; }

    virtual string    GetTime() const override { return time; }
    virtual string    GetSymbol() const override { return symbol; }
    virtual int       GetDir() const override { return dir; }
    virtual int       GetType() const override { return type; }
    virtual void      SetType(int t) override { type = t; }
    virtual double    GetPriceSignal() const override { return price_signal; }
    virtual void      UpdatePriceSignal(double p) override { price_signal = p; }
    virtual double    GetOffset() const override { return offset; }
    virtual double    GetStep() const override { return step; }
    virtual double    GetLot() const override { return lot; }
    virtual void      SetLot(double v) override { lot = v; }

    virtual double    GetTEStart() const override { return te_start; }
    virtual double    GetTEStep() const override { return te_step; }
    virtual double    GetTELimit() const override { return te_limit; }
    virtual int       GetTEInterval() const override { return te_interval; }

    virtual double    GetIkTeStart() const override { return ikte_start; }
    virtual double    GetIkTeStep() const override { return ikte_step; }

    virtual double    GetTP() const override { return tp; }
    virtual void      SetTP(double p) override { tp = p; }
    virtual double    GetSL() const override { return sl; }
    virtual void      SetSL(double p) override { sl = p; }
    virtual int       GetTSStart() const override { return ts_start; }
    virtual int       GetTSStep() const override { return ts_step; }

    virtual int       GetCloseType() const override { return close_type; }
    virtual double    GetTrailPrice() const override { return trail_price; }
    virtual double    GetPriceLimit() const override { return price_limit; }
    virtual double    GetPrice() const override { return price; }
    virtual double    GetPriceOpen() const override { return price_open; }
    virtual void      SetPriceOpen(double p) override { price_open = p; }
    virtual double    GetPriceClose() const override { return price_close; }
    virtual double    GetPriceTP() const override { return price_tp; }
    virtual double    GetPriceSL() const override { return price_sl; }

    virtual long      GetTicket() const override { return ticket; }
    virtual void      SetTicket(long t) override { ticket = t; }
    virtual long      GetMagic() const override { return magic; }
    virtual string    GetComment() const override { return comment; }
    virtual string    GetTag() const override { return tag; }
    virtual datetime  GetCreated() const override { return created; }
    virtual datetime  GetUpdated() const override { return updated; }
    virtual double    GetLimitOffset() const override { return limit_offset; }
    virtual void      SetLimitOffset(double v) override { limit_offset = v; }
    virtual double    GetStopOffset() const override { return stop_offset; }
    
    //--- [v11.0] Log Spam Prevention
    virtual int       GetLastStatus() const override { return last_status; }
    virtual void      SetLastStatus(int status) override { last_status = status; }
};

#endif
