#ifndef ICXSIGNAL_MQH
#define ICXSIGNAL_MQH

#include <Object.mqh>

/**
 * @class ICXSignal
 * @brief 신호 엔티티에 대한 추상 인터페이스 (spec.md 2.3 SSOT 준수)
 */
class ICXSignal : public CObject {
public:
    virtual ~ICXSignal() {}

    //--- 기본 정보
    virtual int       GetId() const = 0;
    virtual string    GetSid() const = 0;
    virtual string    GetGid() const = 0;
    virtual int       GetCno() const = 0;
    virtual int       GetSno() const = 0;
    virtual int       GetMsgId() const = 0;
    virtual int       GetRawId() const = 0;

    //--- 명령 및 상태 (Intent & Execution)
    virtual int       GetXAEntry() const = 0;
    virtual int       GetXAExit() const = 0;
    virtual int       GetStatus() const = 0;
    virtual void      SetStatus(int status) = 0;
    virtual string    GetStatusMsg() const = 0;
    virtual void      SetStatusMsg(string msg) = 0;

    //--- 시장 및 매매 정보
    virtual string    GetTime() const = 0;
    virtual string    GetSymbol() const = 0;
    virtual int       GetDir() const = 0;
    virtual int       GetType() const = 0;
    virtual void      SetType(int type) = 0;
    virtual double    GetPriceSignal() const = 0;
    virtual void      UpdatePriceSignal(double price) = 0;
    virtual double    GetOffset() const = 0;
    virtual double    GetStep() const = 0;
    virtual double    GetLot() const = 0;
    virtual void      SetLot(double lot) = 0;

    //--- 트레일링 진입 (Trailing Entry)
    virtual double    GetTEStart() const = 0;
    virtual double    GetTEStep() const = 0;
    virtual double    GetTELimit() const = 0;
    virtual int       GetTEInterval() const = 0;

    //--- 익절 트레일링 (IkTe)
    virtual double    GetIkTeStart() const = 0;
    virtual double    GetIkTeStep() const = 0;

    //--- 리스크 및 목표 (TP/SL)
    virtual double    GetTP() const = 0;
    virtual void      SetTP(double tp) = 0;
    virtual double    GetSL() const = 0;
    virtual void      SetSL(double sl) = 0;
    virtual int       GetTSStart() const = 0;
    virtual int       GetTSStep() const = 0;

    //--- 실행 가격 정보
    virtual int       GetCloseType() const = 0;
    virtual double    GetTrailPrice() const = 0;
    virtual double    GetPriceLimit() const = 0;
    virtual double    GetPrice() const = 0;
    virtual double    GetPriceOpen() const = 0;
    virtual void      SetPriceOpen(double price) = 0;
    virtual double    GetPriceClose() const = 0;
    virtual double    GetPriceTP() const = 0;
    virtual double    GetPriceSL() const = 0;

    //--- 관리 및 추적
    virtual long      GetTicket() const = 0;
    virtual void      SetTicket(long ticket) = 0;
    virtual long      GetMagic() const = 0;
    virtual string    GetComment() const = 0;
    virtual string    GetTag() const = 0;
    virtual datetime  GetCreated() const = 0;
    virtual datetime  GetUpdated() const = 0;
    virtual double    GetLimitOffset() const = 0;
    virtual void      SetLimitOffset(double v) = 0;
    virtual double    GetStopOffset() const = 0;
    
    //--- [v11.0] Log Spam Prevention
    virtual int       GetLastStatus() const = 0;
    virtual void      SetLastStatus(int status) = 0;
};

//--- MQL5 전용 매크로 지원 (컴파일 타임 호환성용)
#define ICX_SIG_ID(s) s.GetId()
#define ICX_SIG_SID(s) s.GetSid()
#define ICX_SIG_STATUS(s) s.GetStatus()

#endif
