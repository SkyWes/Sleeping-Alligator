# Sleeping-Alligator
An MQL5 class for creating multi-symbol/multi-timeframe Alligator indicator objects and scanning for the "sleeping Alligator" as outlined in Bill William's Trading Chaos books.

The Alligator indicator is basically three moving averages shifted into the future which, if used properly, can be a powerful tool for finding areas of accumulation and setting the scale of chart granularity.

This class allows you to create multiple instances of alligators for different timeframes and find programatically the elusive "sleeping Alligator". It uses two methods of quantifying the sleeping Alligator. The first finds a more entangled market:

![Capture2](https://github.com/user-attachments/assets/56c0f223-7f92-4ef8-9d69-d1ba1b741a2d)

The second method finds what I call a pinched gator:

![Capture](https://github.com/user-attachments/assets/8a2905bf-e4e1-4e81-a2b2-50246466e0ff)

There is the option to construct the object without initiallizing the symbol and timeframe, or you can initialize it upon construction.
