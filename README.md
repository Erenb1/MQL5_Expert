# 5ers Final Trading Bot

A sophisticated MQL5 Expert Advisor (EA) that implements a dual ALMA (Adaptive Linear Moving Average) crossover strategy with advanced risk management and trend confirmation.

## 🚀 Features

- **Dual ALMA Strategy**: Uses two ALMA indicators with different periods for trend identification
- **Smart Entry Logic**: Crossover detection with slope confirmation to reduce false signals
- **Advanced Risk Management**: ATR-based stop loss and take profit calculations
- **Distance Filter**: Prevents entries when price is too far from the slow ALMA
- **Reverse Crossover Protection**: Automatically closes positions on opposite crossover signals
- **Wait Mechanism**: Validates trade signals over multiple candles before execution
- **Trading Hours Control**: Configurable trading time windows
- **Custom Trade Manager**: Integrated position management system

## 📊 Strategy Overview

The EA operates on a dual ALMA crossover system:

1. **Fast ALMA** (default: 27 period) - For entry signals
2. **Slow ALMA** (default: 150 period) - For trend direction and slope confirmation

### Entry Conditions
- **Long Entry**: Fast ALMA crosses above Slow ALMA + upward slope confirmation
- **Short Entry**: Fast ALMA crosses below Slow ALMA + downward slope confirmation
- Price must be within acceptable distance from Slow ALMA (ATR-based)
- No existing position on the symbol

### Exit Conditions
- Reverse crossover (automatic position closure)
- ATR-based stop loss and take profit levels

## ⚙️ Configuration Parameters

### ALMA Settings
```mql5
input int alma_period = 27;        // Fast ALMA Period
input double sigma = 6.0;          // Fast ALMA Sigma
input double offset = 0.85;        // Fast ALMA Offset
input int alma_period2 = 150;      // Slow ALMA Period
input double sigma2 = 6.0;         // Slow ALMA Sigma
input double offset2 = 0.85;       // Slow ALMA Offset
```

### Risk Management
```mql5
input double atr_stopfactor = 0.5;    // Stop Loss (ATR multiplier)
input double atr_profitfactor = 1.3;  // Take Profit ratio
input double atr_distance = 2;        // Max distance from ALMA (ATR)
input double lot_size = 0.05;         // Position size
```

### Signal Validation
```mql5
input double slope_threshold = 1;     // Slope sensitivity (pips)
input int wait_candle = 3;           // Candles to wait for confirmation
```

### Trading Hours
```mql5
input int InpStartHour = 6;          // Trading start hour
input int InpStartMinute = 0;        // Trading start minute
input int InpEndHour = 23;           // Trading end hour
input int InpEndMinute = 58;         // Trading end minute
```

## 📁 Required Files

### Core Files
- `final.mq5` - Main EA file
- `trademanager.mqh` - Custom trade management class (included)

### External Dependencies
- `ALMA_v1.mq5` - ALMA indicator by Arnaud Legoux / Dimitris Kouzis-Loukas / Anthony Cascino, implemented by IgorAD

## 🔧 Installation

1. **Download Files**: Clone or download all required files
2. **Copy to MetaTrader**:
   - Place `final.mq5` in `/MQL5/Experts/`
   - Place `trademanager.mqh` in `/MQL5/Include/`
   - Place `ALMA_v1.mq5` in `/MQL5/Indicators/`
3. **Compile**: Open MetaEditor and compile the EA
4. **Attach to Chart**: Drag the EA onto your desired chart

## 📈 Usage Instructions

1. **Backtest First**: Always backtest the strategy on historical data
2. **Parameter Optimization**: Adjust parameters based on your trading style and market conditions
3. **Risk Management**: Set appropriate lot sizes for your account balance
4. **Monitor Performance**: Regularly review EA performance and adjust if needed

## ⚠️ Risk Disclaimer

**Trading foreign exchange and CFDs carries a high level of risk and may not be suitable for all investors.**

- Past performance does not guarantee future results
- This EA is provided for educational and research purposes
- Always test thoroughly on demo accounts before live trading
- Never risk more than you can afford to lose
- Consider seeking advice from an independent financial advisor

## 🛠️ Technical Details

### Key Functions
- `OnTick()`: Main execution loop with crossover detection
- `TradeLogic()`: Entry signal validation and execution
- `alma_slope()`: Trend direction calculation
- `detect_reverse_crossover()`: Exit signal detection
- `isTooFarFromALMA()`: Distance-based entry filter

### Performance Features
- Efficient buffer management
- Error handling for indicator failures
- Multi-timeframe compatibility
- Broker-agnostic pip calculation

## 📝 Version History

- **v1.29**: Current version with enhanced slope calculation and wait mechanism
- Improved crossover detection logic
- Added distance-based entry filtering
- Enhanced position management

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## 📄 License & Attribution

This project is open source. 

### Credits
- **ALMA Indicator**: Originally developed by Dimitris Kouzis-Loukas, and Anthony Cascino
- **ALMA Implementation**: Coded by IgorAD ([igorad2003@yahoo.co.uk](https://www.forexfactory.com/igorad)) from TrendLaboratory
- **Trade Manager**: Custom implementation by repository author
- **Main EA**: Developed by Erenali Balcıkardeşler

## 🙋‍♂️ Support

For questions, issues, or suggestions:
- Open an issue on GitHub
- Ensure you've read the documentation thoroughly
- Provide detailed information about your setup and the issue

## 🎯 Roadmap

Future enhancements may include:
- Multi-symbol support
- Additional confirmation indicators
- Advanced money management
- Strategy optimization features
- Performance analytics dashboard

---

**Note**: This EA uses the ALMA_v1.mq5 indicator originally developed by Dimitris Kouzis-Loukas, and Anthony Cascino, implemented by IgorAD from TrendLaboratory. All credits and copyrights for the ALMA indicator are preserved and respected.
