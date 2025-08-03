//+------------------------------------------------------------------+
//|                                                        Final.mq5 |
//|                                           Copyright 2024,Erenali |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Erenali Balcıkardeşler."
#property version   "1.29"
#include <Trade\Trade.mqh>
#include  <trademanager.mqh>
TradeManager trademng; // Create an instance of custom trademanager class
CTrade trade; // Create an instance of the CTrade class
CPositionInfo m_position ;
//Indicator Settings
input int alma_period = 27;     // Period for ALMA
input double sigma = 6.0;       // Sigma for ALMA
input double offset = 0.85;      // Shift for ALMA
input double slope_threshold = 1; // How many pips of change in alma is good to consider for slope calculation
input int alma_period2 = 150;     // Period for ALMA2
input double sigma2 = 6.0;       // Sigma for ALMA2
input double offset2 = 0.85;      // Shift for ALMA2
//Indıcator Values
double alma_handle;             // Handle for the ALMA indicator
double alma_handle2;             // Handle for the ALMA indicator
double atr_handle;              // Handle for the ATR indicator
double supertrend_handle;       // Handle for the Supertrend indicator
double alma_value[];            // ALMA values for first period
double alma_value2[];            // ALMA2 values for first period
double atr_value[];             // ATR values
double supertrend_values[];      // Supertrend values 
double super_trend;
//Period for EA
input int      InpStartHour = 6; // This section dictates the operation period for bot
input int      InpStartMinute = 0;
input int      InpEndHour = 23;
input int      InpEndMinute = 58;
//Position Parameters
input double atr_stopfactor = 0.5; // HOW MANY ATR's FROM ALMA is SL  
input double atr_profitfactor = 1.3; // P/L RATIO
input int  supertrend_atr =  10 ; // Supertrend atr period
input double super_trend_xatr = 1.8 ; // Supertrend atr multiplier
input int wait_candle = 3;         // Determine how many candles to wait for the slope to correlate with crossover
input double atr_distance = 2; // How many ATR is too far from ALMA
input double lot_size = 0.05;
bool wait = false;
int current_bar  =  0  ; // Track current bar number
int enter_candle = 0; // last entry candle index
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   atr_handle = iATR(_Symbol,PERIOD_CURRENT,14);
   alma_handle = iCustom(NULL, 0,"ALMA_v1", alma_period,sigma,offset,0,0);
   alma_handle2 = iCustom(NULL, 0,"ALMA_v1", alma_period2,sigma2,offset2,0,0);
   
    // Verify handles
    if (alma_handle == INVALID_HANDLE ||alma_handle2 == INVALID_HANDLE || atr_handle == INVALID_HANDLE) {
        Print("Indicator handle error. ALMA: ", alma_handle,  " ATR: ", atr_handle , "ALMA2:" , alma_handle2);
        return INIT_FAILED;
    }
    Print("Initialization Successful");
    return INIT_SUCCEEDED;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    // Release indicator handle
   if (alma_handle != INVALID_HANDLE)
      IndicatorRelease(alma_handle);
      if (alma_handle2 != INVALID_HANDLE)
      IndicatorRelease(alma_handle2);
   if (atr_handle != INVALID_HANDLE)
      IndicatorRelease(atr_handle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    int bar_number = Bars(_Symbol, _Period);

    // Fetch indicator buffers
    if (CopyBuffer(alma_handle, 0, 0, 5, alma_value) < 5) {
        Print("Failed to copy ALMA1. Error: ", GetLastError());
        return;
    }

    if (CopyBuffer(alma_handle2, 0, 0, 5, alma_value2) < 5) {
        Print("Failed to copy ALMA2. Error: ", GetLastError());
        return;
    }

    if (CopyBuffer(atr_handle, 0, 0, 5, atr_value) < 5) {
        Print("Failed to copy ATR. Error: ", GetLastError());
        return;
    }

    // Detect crossover using closed bars only
    double current_fast = alma_value[4];
    double previous_fast = alma_value[3];
    double current_slow = alma_value2[4];
    double previous_slow = alma_value2[3];

    string entry_signal = "";
    if (previous_fast <= previous_slow && current_fast > current_slow) {
        entry_signal = "Buy";
    }
    else if (previous_fast >= previous_slow && current_fast < current_slow) {
        entry_signal = "Sell";
    }

    // Detect trend slope
    int slope = alma_slope(alma_value2, _Symbol, slope_threshold);

    // Close if reversal crossover is detected
    if (detect_reverse_crossover(alma_value, alma_value2)) {
        Print("Reverse crossover detected. Closing all positions.");
        trademng.CloseAllPositions();
        return;
    }

    // Trading decision
    if (!wait) {
         TradeLogic(alma_value,alma_value2,atr_value,atr_stopfactor,atr_distance,lot_size,entry_signal,slope,wait_candle,wait,current_bar,enter_candle);
    } else {
        int candles_passed = bar_number - current_bar;
        if (candles_passed <= wait_candle) {
            int slope_wait = alma_slope_wait(alma_value2, _Symbol, slope_threshold, candles_passed);
            Print("In wait state. Slope re-check: ", slope_wait, ", entry_signal: ", entry_signal);

            if (entry_signal == "Buy" && slope_wait == 1) {
                Print("Wait Buy signal confirmed. Sending Buy Order...");
                trademng.OpenBuyOrder(lot_size, atr_value, alma_value2, atr_stopfactor, atr_profitfactor);
                enter_candle = bar_number;
                wait = false;
            }
            else if (entry_signal == "Sell" && slope_wait == -1) {
                Print("Wait Sell signal confirmed. Sending Sell Order...");
                trademng.OpenSellOrder(lot_size, atr_value, alma_value2, atr_stopfactor, atr_profitfactor);
                enter_candle = bar_number;
                wait = false;
            }
        }
        else {
            Print("Wait period expired. Resetting wait.");
            wait = false;
        }
    }
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Checks the distance between slow alma and price                                                  |
//+------------------------------------------------------------------+
bool isTooFarFromALMA(double &alma_value2[], double &atr_value[], double atr_distance)
{
    // Get last COMPLETED candle's close price (index 1)
    double last_open = iOpen(_Symbol, _Period, 0);
    
    // Get last COMPLETED ALMA value (index 1)
    double last_alma = alma_value2[4];
    
    // Calculate distance and threshold
    double distance = MathAbs(last_open - last_alma);
    double threshold = atr_distance * atr_value[4];
    
    // Debug print to verify calculations

    return (distance > threshold); // True if TOO FAR
}
//+-----------------------------------------------------------------+
//| Calculate the slope of ALMA                                                 |
//+------------------------------------------------------------------+
int alma_slope_wait(double &alma_value2[], string symbol, double thres,int mismatch_index) 
{
    // Get the correct pip size (accounts for JPY pairs)
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3 || 
       SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5) 
    {
        pip_size *= 10; // Adjust for 3/5 digit brokers
    }
    
    double threshold = thres * pip_size;
    if(alma_value2[4] - alma_value2[mismatch_index] > threshold) 
    {
        return 1; // Uptrend (ALMA rising)
    }
    else if(alma_value2[mismatch_index] - alma_value2[4] > threshold) 
    {
        return -1;  // Downtrend (ALMA falling)
    }
    
    return 0; // No significant trend
}
//+-----------------------------------------------------------------+
//| Calculate the slope of ALMA REGARDING WAIT MODE   
//+------------------------------------------------------------------+
int alma_slope(double &alma_value2[], string symbol, double thres) 
{
    // Get the correct pip size (accounts for JPY pairs)
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3 || 
       SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5) 
    {
        pip_size *= 10; // Adjust for 3/5 digit brokers
    }
    
    double threshold = thres * pip_size;
    if(alma_value2[4] - alma_value2[3] > threshold) 
    {
        return 1; // Uptrend (ALMA rising)
    }
    else if(alma_value2[3] - alma_value2[4] > threshold) 
    {
        return -1;  // Downtrend (ALMA falling)
    }
    
    return 0; // No significant trend
}
//+------------------------------------------------------------------+
//| Controls trading periods                                                 |
//+------------------------------------------------------------------+
bool InTradingTime(TradeManager &tradeManager) {
   datetime Now = TimeCurrent();
   MqlDateTime NowStruct;
   TimeToStruct(Now, NowStruct);
   
   int StartTradingSeconds = (InpStartHour * 3600) + (InpStartMinute * 60);
   int EndTradingSeconds = (InpEndHour * 3600) + (InpEndMinute * 60);
   int runningseconds = (NowStruct.hour * 3600) + (NowStruct.min * 60);

   ZeroMemory(NowStruct);

   if ((runningseconds > StartTradingSeconds) && (runningseconds < EndTradingSeconds)) {
  
      return true; // Trading is allowed
   } else {
  // Close all positions if outside trading hours
      return false; // Trading is not allowed
   }
}
//+------------------------------------------------------------------+
//|  DETECT REVERSE CROSSOVER
//+------------------------------------------------------------------+
bool detect_reverse_crossover(double &alma_value[], double &alma_value2[]) {
    double current_fast = alma_value[4];     // Most recent candle
    double previous_fast = alma_value[3];    // Candle before the most recent
    double current_slow = alma_value2[4];
    double previous_slow = alma_value2[3];

    bool open_pos = trademng.PositionExists(_Symbol);

    if(open_pos) {
        long posType;
        if(PositionSelect(_Symbol)) {
            posType = PositionGetInteger(POSITION_TYPE);

            if(posType == POSITION_TYPE_BUY) {
                // For long positions, detect bearish crossover
                if(previous_fast >= previous_slow && current_fast < current_slow) {
                    Print("Reverse crossover detected for long position: Closing position ...");
                    return true;
                }
            }
            else if(posType == POSITION_TYPE_SELL) {
                // For short positions, detect bullish crossover
                if(previous_fast <= previous_slow && current_fast > current_slow) {
                    Print("Reverse crossover detected for short position: Closing position ...");
                    return true;
                }
            }
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//| Strategy                                                
//+------------------------------------------------------------------+
void TradeLogic(double &alma_value[], double &alma_value2[], double &atr_value[], double atr_stopfactor, double atr_distance, double lot_size, string &entry_signal, int slope, int wait_candle, bool &wait, int &current_bar, int &enter_candle)
{
    int current_bar_cool = Bars(_Symbol, _Period); // Track current bar number

    Print("=== Entering TradeLogic ===");
    Print("entry_signal: ", entry_signal);
    Print("slope: ", slope);
    Print("current_bar: ", current_bar);
    Print("enter_candle: ", enter_candle);
    Print("current_bar_cool (Bars): ", current_bar_cool);
    Print("PositionSelect(_Symbol): ", PositionSelect(_Symbol));

    // Check distance from ALMA
    bool tooFar = isTooFarFromALMA(alma_value2, atr_value, atr_distance);
    Print("Distance from ALMA too far: ", tooFar);

    // Skip trade logic if there's an open position
    if (PositionSelect(_Symbol)) {
        Print("Position already exists, skipping trade.");
        wait = false;
        return;
    }

    // Execute trade if all conditions are met
    if (entry_signal == "Buy" && slope == 1 && current_bar_cool != enter_candle && !tooFar) {
        trademng.OpenBuyOrder(lot_size, atr_value, alma_value2,atr_stopfactor, atr_profitfactor);
        enter_candle = Bars(_Symbol, _Period);
        wait = false;
    }
    else if (entry_signal == "Sell" && slope == -1 && !tooFar && current_bar_cool != enter_candle) {
        trademng.OpenSellOrder(lot_size, atr_value,alma_value2, atr_stopfactor, atr_profitfactor);
        enter_candle = Bars(_Symbol, _Period);
        wait = false;
    }
    else {
        if ((entry_signal == "Buy" && slope != 1) || (entry_signal == "Sell" && slope != -1)){
            Print("Reason: Slope and entry signal mismatch.");
            wait = true;
      }
    }
}
