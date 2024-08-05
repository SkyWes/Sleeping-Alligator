//+------------------------------------------------------------------+
//|                                                SleepingGator.mqh |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSleepingGator
  {
public:
                     CSleepingGator(string symbol, ENUM_TIMEFRAMES tf) : m_symbol(symbol), m_period(tf) { Init(m_symbol,m_period); }
                     CSleepingGator() {};
                    ~CSleepingGator(void);
   //Methods
   bool              Init(string symbol,ENUM_TIMEFRAMES period);
   bool              FindSleepingGator(int indx, ENUM_TIMEFRAMES period);
   bool              CopyBufferVals(int indx, ENUM_TIMEFRAMES period);
   //setters         // Default settings found to capture most cases. Experiment for varying degrees of pinch and pinch length.
   void              SinceNap(int m = 50)    {sincenap = m;}
   void              NapLen(int m = 5)      {naplen = m;}
   void              AvgRangeLen(int m = 50) {avgrangelen = m;}
   void              PinchRatio(int m = 5)  {pinchratio = m;}
   void              BufferLen(int m = 55)   {gator_buffer_len = m;}
   void              SetGatorSymbol(string s) { m_symbol = s; }
   //getters
   double            Lips(int indx) { return(lips[indx]);  }
   double            Teeth(int indx) { return(teeth[indx]); }
   double            Jaw(int indx)  { return(jaw[indx]);   }

   bool              BullTrend() {return(m_bull);}
   bool              BearTrend() {return(m_bear);}

private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   //Settings
   int               sincenap;                      //Max bars since nap
   int               naplen;                        //Min nap length
   int               avgrangelen;                 //Length of average bar range.
   int               pinchratio;
   int               gator_buffer_len;
   //Arrays
   
   double            High[],Low[],ranges[];    // arrays
   double            lips[],teeth[],jaw[];
   //shift
   int               l_shift;
   int               t_shift;
   int               j_shift;
   //Trending
   bool              m_bear;
   bool              m_bull;
  };

void CSleepingGator::~CSleepingGator(void) {}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSleepingGator::Init(string symbol,ENUM_TIMEFRAMES period)
  {

   l_shift = 3;
   t_shift = 5;
   j_shift = 8;

   m_period = period;
   m_symbol = symbol;
   m_bear = false;
   m_bull = false;
   SinceNap();
   NapLen();
   AvgRangeLen();
   PinchRatio();
   BufferLen();

   ArrayResize(ranges,avgrangelen+2);
   ArrayResize(High,gator_buffer_len);
   ArrayResize(Low,gator_buffer_len);
   ArrayResize(lips,gator_buffer_len);
   ArrayResize(teeth,gator_buffer_len);
   ArrayResize(jaw,gator_buffer_len);

   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(lips,true);
   ArraySetAsSeries(teeth,true);
   ArraySetAsSeries(jaw,true);


   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSleepingGator::CopyBufferVals(int indx, ENUM_TIMEFRAMES period)
  {
   int h_alligator=iAlligator(m_symbol,period,13,0,8,0,5,0,MODE_SMMA,PRICE_MEDIAN);
   if(h_alligator==INVALID_HANDLE)
     {
      Print(__FUNCTION__,"ERROR, Invalid Handle, period: ",period," symbol : ",m_symbol);
      return(false);
     }

   int high = CopyHigh(m_symbol,period,0,gator_buffer_len,High);
   int low = CopyLow(m_symbol,period,0,gator_buffer_len,Low);
   if(high<avgrangelen || low<avgrangelen)
     {
      Print("Copy prices for ",m_symbol," failed: highcount = ",high," lowcount = ",low, __FUNCTION__);
      return(false);
     }
   int copyCount=-1;
   int i{};

   copyCount=CopyBuffer(h_alligator,0,5,gator_buffer_len,jaw); // Jaw

   if(copyCount<5)
     {
      Print("Failed to copy bars for ",m_symbol," jaw indx ",indx,", period ",EnumToString(period),". Error = ",GetLastError()," copied = ",copyCount);
      return(false);
     }


   copyCount=CopyBuffer(h_alligator,1,2,gator_buffer_len,teeth); // Teeth
   if(copyCount<5)
     {
      Print("Failed to copy bars for ",m_symbol," teeth indx ",indx,", period ",EnumToString(period),". Error = ",GetLastError()," copied = ",copyCount);
      return(false);
     }

   copyCount=CopyBuffer(h_alligator,2,0,gator_buffer_len,lips); // Lips
   if(copyCount<5)
     {
      Print("Failed to copy bars for ",m_symbol," lips indx ",indx,", period ",EnumToString(period),". Error = ",GetLastError()," copied = ",copyCount);
      return(false);
     }

//Print("m_period: ",EnumToString(period)," m_symbol :",m_symbol," Bar[1]-lips[1]: ",lips[1]," teeth[1]: ",teeth[1]," jaw[1]: ",jaw[1]);

   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSleepingGator::FindSleepingGator(int indx, ENUM_TIMEFRAMES period)
  {
   if(!CopyBufferVals(indx, period))
      return false;

   bool method_found=false;
   int buytrendcount=0;
   int selltrendcount=0;
   int profitabletrendlen=5;

//Method one finds entangeld alligator
   for(int gatorindex=0; gatorindex < gator_buffer_len; gatorindex++)
     {
      if(lips[gatorindex]>teeth[gatorindex] && teeth[gatorindex]>jaw[gatorindex])
        {
         if(gatorindex==1)
           {
            m_bear = false;
            m_bull = true;
            // Print("Htf bull_trend");
           }
         buytrendcount+=1;
         selltrendcount=0;
         if(buytrendcount>profitabletrendlen)
           { break; }
         continue;
        }
      else
         if(lips[gatorindex]<teeth[gatorindex] && teeth[gatorindex]<jaw[gatorindex])
           {
            if(gatorindex==1)
              {
               m_bear = true;
               m_bull = false;
               //   Print("Htf bear_trend");
              }
            selltrendcount+=1;
            buytrendcount=0;

            if(selltrendcount>profitabletrendlen)
              { break; }
            continue;
           }
      if((lips[gatorindex]<teeth[gatorindex] && teeth[gatorindex]>jaw[gatorindex]) ||
         (lips[gatorindex]>teeth[gatorindex] && teeth[gatorindex]<jaw[gatorindex]))
        {
         if(gatorindex==1)
           {
            m_bear = false;
            m_bull = false;
           }
         selltrendcount=0;
         buytrendcount=0;
        }
      if(gatorindex == gator_buffer_len - 1)
        {
         method_found = true;
        }
     }

// Method two finds pinched alligator
   double avgrange;
   double gatorRange[];
   ArrayResize(gatorRange,sincenap+1);
   int k=0;
   double summation = 0;

   for(int i=1; i<=avgrangelen && !_StopFlag; i++)
     {
      ranges[k]=(High[i]-Low[i]);
      summation += ranges[k];
      k++;
     }

   avgrange=summation/avgrangelen;

   int    gatornap=0;
   for(int a=sincenap; a >= 0 && !_StopFlag; a--)      //a=13, a=3, or a=5 seem best
     {
      double maxgator= MathMax(lips[a], MathMax(teeth[a],jaw[a]));
      double mingator= MathMin(lips[a], MathMin(teeth[a],jaw[a]));

      gatorRange[a]= maxgator-mingator;
      if(gatorRange[a]<(avgrange/pinchratio))      //avgrange=5 or 8 seem best.
        {gatornap++;}
     }


   if(gatornap>naplen)
     {
      method_found = true;
     }

//Returns true if either method is found.
   return method_found;

  }
//+------------------------------------------------------------------+
