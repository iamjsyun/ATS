//+------------------------------------------------------------------+
//| Data structure for error handling                                |
//+------------------------------------------------------------------+
struct MqlError
  {
   int      code;          // Cod of error
   string   description;   // Description of error
   string   constant;      // Type error
   
   MqlError::MqlError(void)
     {
      code = 0;
      description = "";
      constant = "";
     }
  };
//+------------------------------------------------------------------+