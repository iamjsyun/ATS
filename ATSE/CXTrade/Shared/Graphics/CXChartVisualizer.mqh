#ifndef CXCHARTVISUALIZER_MQH
#define CXCHARTVISUALIZER_MQH

#include "..\..\Core\Interfaces\ICXSignal.mqh"
#include <ChartObjects\ChartObjectsLines.mqh>

/**
 * @class CXChartVisualizer
 * @brief [v16.20] 트레이딩 트리거 라인 시각화 유틸리티
 */
class CXChartVisualizer {
public:
    /**
     * @brief TE Start 트리거 라인 드로잉
     * @param sig 대상 신호
     * @param triggerPrice 계산된 트리거 가격
     */
    static void DrawTEStart(ICXSignal* sig, double triggerPrice) {
        if(IS_INVALID(sig) || triggerPrice <= 0) return;

        string name = "TE_START_" + sig.GetSid();
        color clr = (sig.GetDir() == CX_DIR_BUY) ? clrBlue : clrPink;
        
        CChartObjectHLine line;
        if(ObjectFind(0, name) < 0) {
            line.Create(0, name, 0, triggerPrice);
        } else {
            line.Attach(0, name, 0, 1);
            line.Price(0, triggerPrice);
        }

        line.Color(clrBlue); // [v16.27] Always Blue per request
        line.Width(1);
        line.Style(STYLE_SOLID); // [v16.27] Solid line for distinction
        line.Description("TE Start Trigger (" + sig.GetSid() + ")");
        
        ChartRedraw(0);
    }

    /**
     * @brief 시각화 객체 제거 (세션 종료 시)
     */
    static void RemoveTEStart(ICXSignal* sig) {
        if(IS_INVALID(sig)) return;
        string name = "TE_START_" + sig.GetSid();
        ObjectDelete(0, name);
    }
};

#endif
