#ifndef CXUI_MQH
#define CXUI_MQH

#include <Object.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include "..\Core\Interfaces\ICXContext.mqh"
#include "..\Core\Interfaces\ICXSignal.mqh"
#include "..\Core\Interfaces\IRepository.mqh"
#include "..\Core\Interfaces\ICXPriceManager.mqh"
#include "..\Core\Macros\CXMacros.mqh"
#include "..\..\App\Logic\CXTerminalScanner.mqh"
#include "..\..\Platform\Core\Models\CXTerminalAsset.mqh"

// 렌더링에 사용되는 행별 UI 객체 구조체 (10개 슬롯 대응)
struct MqlUIElement {
    CChartObjectLabel      Line1;       // SID, 정수 설정값, 상태 표시
    CChartObjectLabel      Line2;       // 계산된 가격값들
};

/**
 * @class CXUI
 * @brief ATSE 차트 화면 내 실시간 세션 정보 대시보드 가시화 컴포넌트
 */
class CXUI : public CObject {
private:
    ICXContext*       m_ctx;              // 서비스 컨텍스트 의존성
    MqlUIElement      m_elements[10];     // 최대 10개 세션 슬롯 관리
    
    // UI 스타일 구성
    color             m_color_text;
    int               m_font_size;
    string            m_font_name;

    // 차트 레이아웃 좌표
    int               m_x_offset;
    int               m_y_offset;
    int               m_slot_spacing;
    int               m_line_spacing;

public:
    /**
     * @brief 생성자
     */
    CXUI(ICXContext* ctx) : m_ctx(ctx),
                            m_color_text(clrGold),
                            m_font_size(11),
                            m_font_name("Consolas"),
                            m_x_offset(20),
                            m_y_offset(60),
                            m_slot_spacing(40),
                            m_line_spacing(16) {
    }

    /**
     * @brief 소멸자
     */
    virtual ~CXUI() override {
        Deinitialize();
    }

    /**
     * @brief 차트 라벨 리소스 최초 생성 및 초기화
     */
    bool Initialize() {
        for(int i = 0; i < 10; i++) {
            string nameL1 = StringFormat("CXUI_%d_L1", i);
            string nameL2 = StringFormat("CXUI_%d_L2", i);

            int yPosL1 = m_y_offset + (i * m_slot_spacing);
            int yPosL2 = yPosL1 + m_line_spacing;

            // Line 1 생성 및 기본 설정
            if(!m_elements[i].Line1.Create(0, nameL1, 0, m_x_offset, yPosL1)) return false;
            m_elements[i].Line1.Font(m_font_name);
            m_elements[i].Line1.FontSize(m_font_size);
            m_elements[i].Line1.Color(m_color_text);
            m_elements[i].Line1.Description(" ");

            // Line 2 생성 및 기본 설정
            if(!m_elements[i].Line2.Create(0, nameL2, 0, m_x_offset, yPosL2)) return false;
            m_elements[i].Line2.Font(m_font_name);
            m_elements[i].Line2.FontSize(m_font_size);
            m_elements[i].Line2.Color(m_color_text);
            m_elements[i].Line2.Description(" ");
        }
        ChartRedraw(0);
        return true;
    }

    /**
     * @brief 차트 내 생성한 리소스 완벽한 소멸 처리 (누수 방지)
     */
    void Deinitialize() {
        for(int i = 0; i < 10; i++) {
            m_elements[i].Line1.Delete();
            m_elements[i].Line2.Delete();
        }
        ChartRedraw(0);
    }
    
    /**
     * @brief 실시간 리 렌더링 (OnTick / OnTimer에서 주기적 호출)
     */
    void Refresh() {
        if(IS_INVALID(m_ctx)) return;

        IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
        if(IS_INVALID(repo)) return;

        ICXPriceManager* priceMgr = CX_GET_OBJ(m_ctx, "price_mgr", ICXPriceManager);

        CXTerminalScanner scanner;
        CArrayObj* assetList = new CArrayObj();
        assetList.FreeMode(true);
        scanner.ScanAll(assetList);

        CArrayObj* activeList = new CArrayObj();
        activeList.FreeMode(true);

        for(int i = 0; i < assetList.Total(); i++) {
            CXTerminalAsset* asset = CX_CAST(CXTerminalAsset, assetList.At(i));
            if(IS_VALID(asset)) {
                bool duplicate = false;
                for(int j = 0; j < activeList.Total(); j++) {
                    ICXSignal* existing = CX_CAST(ICXSignal, activeList.At(j));
                    if(IS_VALID(existing) && existing.GetSid() == asset.sid) {
                        duplicate = true;
                        break;
                    }
                }
                if(duplicate) continue;

                ICXSignal* sig = repo.GetSignalBySid(asset.sid);
                if(IS_VALID(sig)) {
                    activeList.Add(sig);
                }
            }
        }

        int renderCount = MathMin(activeList.Total(), 10);

        for(int i = 0; i < 10; i++) {
            if(i < renderCount) {
                ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
                if(IS_VALID(sig)) {
                    UpdateSlot(i, sig, priceMgr);
                } else {
                    ClearSlot(i);
                }
            } else {
                ClearSlot(i);
            }
        }

        SAFE_DELETE(assetList);
        SAFE_DELETE(activeList);
        ChartRedraw(0);
    }

private:
    /**
     * @brief 개별 슬롯에 활성 신호 데이터 바인딩 및 출력
     */
    void UpdateSlot(int slotIdx, ICXSignal* sig, ICXPriceManager* priceMgr) {
        string symbol = sig.GetSymbol();
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double dirSign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;

        // 실시간 기준가 획득 (SSOC)
        double currentPrice = 0;
        if(IS_VALID(priceMgr)) {
            currentPrice = priceMgr.GetLiquidationPrice(symbol, (ENUM_CX_DIRECTION)sig.GetDir());
        } else {
            currentPrice = SymbolInfoDouble(symbol, (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_ASK : SYMBOL_BID);
        }

        // 상태 판정 (포지션 vs 대기오더)
        bool isPosition = (sig.GetStatus() >= XE_EXECUTED && sig.GetStatus() < XE_CLOSED_SIGNAL);
        string p0_lbl, p1_lbl, p2_lbl;
        double p0, p1, p2;

        if(isPosition) {
            // 포지션 모드: TP 및 Trailing Stop 정보 표시
            p0_lbl = "TP";     p0 = sig.GetPriceTP();
            p1_lbl = "SSTART"; p1 = currentPrice + (sig.GetTSStart() * point * -dirSign); // TS는 가격 뒤를 따름
            p2_lbl = "SSTEP";  p2 = currentPrice + (sig.GetTSStep() * point * -dirSign);
        } else {
            // 대기오더 모드: 진입가 및 Trailing Entry 정보 표시
            p0_lbl = "LIMIT";  p0 = sig.GetPriceOpen();
            p1_lbl = "ESTART"; p1 = currentPrice + (sig.GetTEStart() * point * dirSign);  // TE는 가격 앞을 따름
            p2_lbl = "ESTEP";  p2 = currentPrice + (sig.GetTEStep() * point * dirSign);
        }

        // Line 1: {SID} {te_start} | {te_step} | {te_limit} [{state}]
        string stateStr = GetStateName((ENUM_XE_STATUS)sig.GetStatus());
        string txtL1 = StringFormat("%s  %d | %03d | %d  [%s]",
                                    sig.GetSid(),
                                    (int)sig.GetTEStart(),
                                    (int)sig.GetTEStep(),
                                    (int)sig.GetTELimit(),
                                    stateStr);

        // Line 2: ┗━ {p0_lbl}: {p0}    {p1_lbl}: {p1}   {p2_lbl}: {p2}
        string txtL2 = StringFormat(" ┗━ %s: %s    %s: %s   %s: %s",
                                    p0_lbl, DoubleToString(p0, digits),
                                    p1_lbl, DoubleToString(p1, digits),
                                    p2_lbl, DoubleToString(p2, digits));

        // 색상 적용 (포지션: Gold, 대기오더: Wheat)
        color slotColor = isPosition ? clrGold : clrWheat;
        m_elements[slotIdx].Line1.Color(slotColor);
        m_elements[slotIdx].Line2.Color(slotColor);

        m_elements[slotIdx].Line1.Description(txtL1);
        m_elements[slotIdx].Line2.Description(txtL2);
    }

    /**
     * @brief 미사용 슬롯 비우기 및 공백 처리 (" " 대치)
     */
    void ClearSlot(int slotIdx) {
        m_elements[slotIdx].Line1.Description(" ");
        m_elements[slotIdx].Line2.Description(" ");
    }

    /**
     * @brief 엔진 상태명 포매팅 헬퍼
     */
    string GetStateName(ENUM_XE_STATUS status) {
        switch(status) {
            case XE_READY:          return "READY";
            case XE_PENDING_REQ:    return "PEND_REQ";
            case XE_IN_TRANSIT:     return "TRANSIT";
            case XE_PENDING_PLACED: return "PENDING";
            case XE_EXECUTED:       return "ACTIVE";
            case XE_CLOSED_SIGNAL:  return "CLOSED";
            case XE_CLOSED_SL:      return "CLOSED_SL";
            case XE_CLOSED_TP:      return "CLOSED_TP";
            case XE_CLOSED_MANUAL:  return "CLSD_MAN";
            case XE_ERROR:          return "ERROR";
            default:                return "UNKNOWN";
        }
    }
};

#endif
