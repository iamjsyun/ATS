//+------------------------------------------------------------------+
//|                                                      XArrays.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


class XArray {

public:


 template<typename T>class FloatingPoint {
   public:
      FloatingPoint() {
         Precision(sizeof(T));
      }
      int               Compare(const T x, const T y) {
         return (((fabs(x - y) < min)) ? 0 : ((x - y >= min)) ? 1 : -1);
      }
      void              Precision(int digits) {
         min = pow(10, -fabs(digits));
      }
   protected:
      double            min;
   };



   class Types {
   public:
      bool Types::IsSimple(string type) {
         return (type == "char" || type == "uchar"
                 || type == "short" || type == "ushort"
                 || type == "int" || type == "uint"
                 || type == "long" || type == "ulong"
                 || type == "float" || type == "double"
                 || (StringFind(type, "ENUM") > -1) || type == "datetime"
                 || type == "bool" || type == "color");
      }
      bool              IsFloatingPoint(string type) {
         return (type == "float" || type == "double");
      }


      bool Types::IsNumeric(string type) {
         return (type == "char" || type == "uchar"
                 || type == "short" || type == "ushort"
                 || type == "int" || type == "uint"
                 || type == "long" || type == "ulong"
                 || type == "float" || type == "double");
      }

      bool              IsComplex(string type) {
         return (!IsSimple(type));
      }

      template<typename T>int Bits(T src) {
         return sizeof(typename(T)) * 8;
      }
      template<typename T>int BitsByref(T &src) {
         return sizeof(typename(T)) * 8;
      }
      template<typename T>int Bits(T &src[]) {
         return sizeof(typename(T)) * 8;
      }
   };

  




   /****************************************************************/
   template<typename T>double  Min(T &src[]) {
      if(!types.IsNumeric(typename(T))) {
         return -1.;
      }
      int id = ArrayMinimum(src);
      return (id == -1) ? id : src[id];
   }
   /****************************************************************/
   template<typename T>double  Max(T &src[]) {
      if(!types.IsNumeric(typename(T))) {
         return -1.;
      }
      int id = ArrayMaximum(src);
      return (id == -1) ? id : src[id];
   }
   /****************************************************************/
   template<typename T>double  Sum(T &src[]) {
      if(!types.IsNumeric(typename(T))) {
         return -1.;
      }
      double sum = 0.;
      int size = ArraySize(src);
      for(int i = 0; i < size; i++) {
         sum += src[i];
      }
      return sum;
   }
   /****************************************************************/
   template<typename T>double  Average(T &src[]) {
      if(!types.IsNumeric(typename(T))) {
         return -1.;
      }
      double sum = Sum(src);
      int size = ArraySize(src);
      return (sum / ((size) ? size : 1));
   }
   /****************************************************************/
   template<typename T>bool  Insert(T &dst[], T &src[], int dststart) {
      /*CHECK*/
      int sizedst = ArraySize(dst);
      int sizesrc = ArraySize(src);
      if(dststart > sizedst || dststart < 0) {
         PrintFormat("%s: dststart parameter out of range: %d", __FUNCTION__, dststart);
         return false;
      }
      /*INSERT ARRAY*/
      T tmp[];
      Copy(tmp, dst, 0, 0, 0, dststart);
      Copy(tmp, src, 0, dststart);
      Copy(tmp, dst, 0, dststart + sizesrc, dststart);
      Copy(dst, tmp, 1);
      return true;
   }
   /****************************************************************/
   template<typename T>bool  Insert(T element, T &array[], int pos) {
      /*CHECK*/
      if(pos > ArraySize(array) || pos < 0) {
         PrintFormat("%s: pos parameter out of range: %d", __FUNCTION__, pos);
         return false;
      }
      /*INSERT ELEMENT*/
      T tmp[];
      Copy(tmp, array, 0, 0, 0, pos);
      Add(element, tmp);
      Copy(tmp, array, 0, pos + 1, pos);
      Copy(array, tmp, 1);
      return true;
   }
   /****************************************************************/
   template<typename T>bool  Insertbyref(T &element, T &array[], int pos) {
      if(pos > ArraySize(array) || pos < 0) {
         PrintFormat("%s: pos parameter out of range: %d", __FUNCTION__, pos);
         return false;
      }
      /*INSERT ELEMENT BY REF*/
      T tmp[];
      Copy(tmp, array, 0, 0, 0, pos);
      Addbyref(element, tmp);
      Copy(tmp, array, 0, pos + 1, pos);
      Copy(array, tmp, 1);
      return true;
   }
   /****************************************************************/
   template<typename T>int  Add(T element, T &array[]) {
      int size = ArraySize(array);
      if(!(ArrayResize(array, size + 1, 0x16) > -1)) {
         Print(__FUNCTION__, ": ArrayResize error: ", GetLastError());
      } else {
         array[size] = element;
      }
      return ArraySize(array);
   }
   /****************************************************************/
   template<typename T>int  Find(T element, T &array[], int start = 0) {
      int ret = -1;
      /*CHECK*/
      int total = ArraySize(array);
      bool outofrange = start < 0 || start > total - 1;
      if(outofrange) {
         PrintFormat("%s: start parameter out of range (%d)", __FUNCTION__, start);
         return -1;
      }
      /*SEARCH*/
      for(int i = start; i < total; i++) {
         T itm = array[i];
         bool elementisitem;
         if(types.IsFloatingPoint(typename(T))) {
            FloatingPoint<T>fp;
            elementisitem = fp.Compare(element, itm) == 0;
         } else {
            elementisitem = element == itm;
         }
         if(elementisitem) {
            ret = i;
            break;
         }
      }
      return ret;
   }
   /****************************************************************
   FindReverse searches for the element from array end.
   /****************************************************************/
   template<typename T>int  FindReverse(T element, T &array[], int start = 0) {
      T copy[];
      Copy(copy, array);
      if(!ArrayReverse(copy)) {
         Print(__FUNCTION__, ": ArrayReverse error: ", GetLastError());
         return -1;
      }
      return Find(element, copy, start);
   }
   /****************************************************************
   Addbyref does the same thing as Add by can work with complex types,
    which are sent only by reference.
   /****************************************************************/
   template<typename T>int  Addbyref(T &element, T &array[]) {
      int size = ArraySize(array);
      if(!(ArrayResize(array, size + 1, 0x10) > -1)) {
         Print(__FUNCTION__, ": ArrayResize error: ", GetLastError());
      } else {
         array[size] = element;
      }
      return ArraySize(array);
   }
   /****************************************************************
   Copy has the same signature/behavior as the standard Mql ArrayCopy.
   Unlike ArrayCopy, it allows complex types in src/dst.
   /****************************************************************/
   template<typename T>int  Copy(T &dst[], T &srs[], bool clean = 0, int dststart = 0, int srcstart = 0, int srccount = -1) {
      /*CLEAN*/
      if(clean) {
         ArrayFree(dst);
         dststart = 0;
      }
      /*SIZES*/
      int sizesrc = ArraySize(srs);
      int sizedst = ArraySize(dst);
      /*CHECK*/
      bool dststartok = dststart >= 0 && dststart <= sizedst;
      bool srcstartok = srcstart >= 0 && srcstart <= sizesrc;
      bool wholearray = srccount == WHOLE_ARRAY;
      bool srccountok = (wholearray) ? true : srccount + srcstart <= sizesrc;
      if(!dststartok || !srcstartok || !srccountok) {
         Print(__FUNCTION__, ": parameters check error");
         return -1;
      }
      bool srccountzero = srccount == 0;
      if(srccountzero) {
         return 0;
      }
      /*RESIZE*/
      srccount = (wholearray) ? sizesrc - srcstart : srccount;
      bool resize = dststart + srccount > sizedst;
      int sizedstnew = dststart + srccount;
      if(resize) {
         ArrayResize(dst, sizedstnew);
      }
      /*COPY*/
      int i, until = srccount;
      for(i = 0; i < until; i++, dststart++, srcstart++) {
         dst[dststart] = srs[srcstart];
      }
      return i;
   }
   /****************************************************************
   StringToCodes is basically the standard StringToShortArray,
    except that the final 0 is removed from the destination array.
   /****************************************************************/
   int  StringToCodes(string src, short &dst[], int startpos = 0, int count = -1) {
      if((StringToShortArray(src, dst, startpos, count))) {
         if(!(ArrayRemove(dst, ArraySize(dst) - 1))) {
            Print(__FUNCTION__, ": ArrayRemove error: ", GetLastError());
         }
      }
      return ArraySize(dst);
   }



   template<typename T>
   string            ToString(T &array[], string delimiter = " ") {
      string s1;
      for(int i = 0 ; i < ArraySize(array) ; i++) {
         StringAdd(s1, StringFormat("%d", array[i]));
         if (i  < ArraySize(array) - 1) {
            StringAdd(s1, delimiter);
         }
      }
      return s1;
   }

   template<typename T>
   bool              Exist(T value, T &array[]) {
      bool result = Find(value, array) >= 0 ? true : false;
      return result;
   }

   template<typename T>
   bool              NotExist(T value, T &array[]) {
      bool result = Find(value, array) <  0 ? true : false;
      return result;
   }

   template<typename T>
   bool              Substract(T &src[], T &dst[], T &out[]) {
      ArrayFree(out);
      for(int i = 0 ; i < ArraySize(src) ; i++ ) {
         if (NotExist(src[i], dst)) {
            Add(src[i], out);
         }
      }
      return true;
   }

   template<typename T>
   bool              Difference(T &a[], T &b[], T &ab[], T &ba[]) {
      ArrayFree(ab);
      ArrayFree(ba);

      for(int i = 0 ; i < ArraySize(a) ; i++ ) {
         if (NotExist(a[i], b)) {
            Add(a[i], ab);
         }
      }
      for(int i = 0 ; i < ArraySize(b) ; i++ ) {
         if (NotExist(b[i], a)) {
            Add(a[i], ba);
         }
      }
      return true;
   }


   template<typename T>
   bool              Intersection(T &a[], T &b[], T &ab[]) {
      ArrayFree(ab);
      ArrayFree(ba);

      for(int i = 0 ; i < ArraySize(a) ; i++ ) {
         if (Exist(a[i], b)) {
            Add(a[i], ab);
         }
      }
      return true;
   }


   template<typename T>
   bool              GetSets(T &a[], T &b[], T &ab[], T &ba[], T &c[]) {
      ArrayFree(ab);
      ArrayFree(ba);
      ArrayFree(c);
      
      Substract(a,b,ab);
      Substract(b,a,ba);

      for(int i = 0 ; i < ArraySize(a) ; i++ ) {
         if (Exist(a[i], b)) {
            Add(a[i], c);
         }
      }
      return true;
   }


// ---------------------------------------------------------


   template<typename T>
   void ArrayAdd(T &array[],   const T elem, int reserve = 0) {
      int size = ArraySize(array);
      if(!(bool)ArrayResize(array, size + 1, reserve))  return;
      array[size] = elem;
   }

   template<typename T>
   void ArrayAdd(T &array[], const T &elem, int reserve = 0  ) {
      int size = ArraySize(array);
      if(!(bool)ArrayResize(array, size + 1, reserve))  return;
      array[size] = elem;
   }

   template<typename T>
   void ArrayAdd(T &array[], const  T &array_add[], int reserve = 0) {
      int i, j;
      int size1 = ArraySize(array);
      int size2 = ArraySize(array_add);
      ArrayResize(array, size1 + size2, reserve);
      for(i = size1, j = 0; j < size2; i++, j++)
         array[i] = array_add[j];
   }


//=============================/ ArrayDelElement /=============================================
   template<typename T>
   void ArrayDel(T &array[], int pos, int length = 1) {
      int size = ArraySize(array);
      int i, j;
      for(i = pos, j = pos + length; j < size; i++, j++)
         array[i] = array[j];
      ArrayResize(array, size - length);
   }
//=============================/ ArrayMaxValue /=============================================
   template<typename T>
   T ArrayMaxValue(const T &array[], int pos = 0, int length = -1) {
      if(length < 0)
         length = WHOLE_ARRAY;
      return array[ArrayMaximum(array, length, pos)];
   }
//=============================/ ArrayMinValue /=============================================
   template<typename T>
   T ArrayMinValue(const T &array[], int pos = 0, int length = -1) {
      if(length < 0)
         length = WHOLE_ARRAY;
      return array[ArrayMinimum(array, length, pos)];
   }
//=============================/ ArrayLast /=============================================
   template<typename T>
   T ArrayLast(const T &array[]) {
      return array[ArraySize(array) - 1];
   }
//=============================/ ArrayLast /=============================================
   template<typename T>
   T ArrayFirst(const T &array[]) {
      return array[0];
   }
//=============================/ ArrayToString /=============================================
   template<typename T>
   string ArrayToString(const T &array[], int pos = 0, int length = -1, string delimeter = " ") {
      int last = (length < 0) ? ArraySize(array) : length + pos;
      string str;
      for(int i = pos; i < last; i++)
         str += string(array[i]) + delimeter;
      return str;
   }




//=============================/ ArrayToString /=============================================
   template<typename T>
   bool ArrayEmpty(const T &array[]) {
      return bool(ArrayFree(array));
   }
//=============================/ ArrayReverse /=============================================
   //template<typename T>
   //void ArrayReverse(T &array[]) {
   //   int i, j;
   //   for(i = 0, j = ArraySize(array) - 1; i < j; i++, j--)
   //      MathSwap(array[i], array[j]);
   //}

   template<typename T>
   bool ArrayContains(T &array[], T value ) {
      bool result = false;
      for(int i = 0 ; i < ArraySize(array) - 1 ; i++) {
         if (array[i] == value) {
            result = true;
            break;
         }
      }
      return result;
   }


protected:
   Types             types;
};
