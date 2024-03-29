//+------------------------------------------------------------------+
//|                                           Water_Investigator.mq4 |
//|                                          Copyright 2021, Gamakiv |
//|                                             https://t.me/gamakiv |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Gamakiv"
#property link      "https://t.me/gamakiv"
#property version   "2.00"
#property description "Вторая весия советника"
#property strict

//------------------------------------------------
extern string Water_Investigator = "Expert parameters";
extern double Lots = 0.01;
extern int    TakeProfit = 0 ;
extern int    StopLoss = 10;
extern int    Slippage = 3;
extern int    Magic = 314;

extern string TrailingP = "TrailingStop parameters";
extern bool   SetTrailing = False;
extern int TralStop = 30;
extern int TralStep = 10;


//------------------------------------------------
extern string HMA_Indicator = "Indicator parameters";
extern int HMA_Period = 20;
extern int HMA_PriceType = 0;
extern int HMA_Method = 3;
extern bool NormalizeValues = True;
extern int NormalizeDigitsPlus = 2;
extern int VerticalShift = 0;

//------------------------------------------------
extern double SMA_Period = 200;
//------------------------------------------------
//Indicator
double SMA;
double pbf_buff_0, pbf_buff_1, pbf_buff_2, pbf_buff_3, pbf_buff_4, pbf_buff_5;
double iHama0, iHama1, iHama3, xHama0, xHama1, xHama3;
bool UseHMA = True;
int check_way_line;

//Money | Order
double SL, TP;
double BalansCurrent;
int Ticket;

//Mail
string TimeFrame;
string text;
string sub;

//files
string screen_name;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (Digits == 3 || Digits == 5)
      {
         TakeProfit *= 10;
         StopLoss *= 10; 
         Slippage *= 10;
         
         TralStop *= 10;
         TralStep *= 10;
      }   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    //буферы HAMA  
    //0 - Сам показатель. Есть всегда.
    //1 - Зеленая линия
    //3 - Красная линия
    
    iHama0 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 0, 0));
    iHama1 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 1, 0));
    iHama3 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 3, 0));

    xHama0 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 0, 1));
    xHama1 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 1, 1));
    xHama3 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 3, 1));
               
    //value2 / bpf_buff_1 - красная линия в зоне перекуплености
    //value3 / pbf_buff_2 - зеленая линия в зоне перепроданости
    //value4 / pbf_buff_3 - желтые точки в зонах перекупл/перепроданости
    //value5 / pbf_buff_4 - красная точка в зоне перекуплености
    //value6 / pbf_buff_5 - зеленая точка в зоне перепроданости
    
    //использую функцию Nullifier всесто этой конструкции   
    //if(iRed == 2147483647.0)
    //  iRed = 0;  
    
    pbf_buff_0 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 0, 0));
    pbf_buff_1 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 1, 0));
    pbf_buff_2 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 2, 0));    
    pbf_buff_3 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 3, 0));    
    pbf_buff_4 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 4, 0));
    pbf_buff_5 = Nullifier(iCustom(NULL, 0, "PBF_OSOB", 5, 0));
    
    SMA = Nullifier(iMA(NULL, 0, SMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0));
    //Comment("SMA = ", SMA);
    //текущая цена любого указанного инструмента MarketInfo(0, MODE_BID);       

//+-------------- CHECKER FILE --------------+

   if(StringLen(CheckCloseOrder()) != 0)
      {    
         string TiketName = CheckCloseOrder();
         Print("Закрываю ордер по телеграм боту");

         OrderClose(StrToInteger(TiketName), Lots, Ask, Slippage, Aqua);
         
         FileDelete("Close/" + TiketName);
         Print("Delete close order file");
         
         FileDelete("Open/" + TiketName);
         Print("Delete close Open order file");
      }
   
//+-------------- MAIN --------------+
   if(CheckNewBar() == True)
      {
       
       //1 = green  2 = Red
       //проверить наличие трех баров одного цвета
       //check_way_line = CheckWay();
       
      //отправить уведомление о перепроданости или перекуплености 
      // и создать файл для ботаa
      // 0 = перепроданость - oversold
      // 1 = перекупленость - overbought
      
       if(CountSell()>=0 && (pbf_buff_5 < 0 || pbf_buff_3 < 0))       
         {           
            ChartScreenShot(0, Symbol()+"/sell/sell.png", 1366, 768, ALIGN_LEFT); //ALIGN_RIGHT         
         }
         
       if(CountBuy()>=0 && (pbf_buff_4 > 0 || pbf_buff_3 > 0))         
         {         
            ChartScreenShot(0, Symbol()+"/buy/buy.png", 1366, 768, ALIGN_LEFT);  //ALIGN_RIGHT         
         }
         
       //Торгуем по HAMA
       if(UseHMA == True)
         {
            //продаем   
            if(CountSell() == 0 && iHama3 < xHama3)
               {
                  CloseBuy();
                  //if((SMA > MarketInfo(0, MODE_BID)) && check_way_line == 2)
                  if((SMA > MarketInfo(0, MODE_BID)))
                     {
                        Print("SMA before sale: ", + SMA);
                        OpenSell();                        
                     }
               }
            
            //покупаем
            if(CountBuy() == 0 && iHama1 > xHama1)
               {               
                  CloseSell();
                  //if((SMA < MarketInfo(0, MODE_BID)) && check_way_line == 1)
                  if((SMA < MarketInfo(0, MODE_BID)))
                     {
                        Print("SMA before Buy: " + SMA);
                        OpenBuy();
                     }
               }                        
         }
         
      } //end if check bar
      
//+---------- END MAIN --------------+           
   
   if(SetTrailing == True)
      {
         TrailingOn();
      }
       
  } //end OnTick
//+------------------------------------------------------------------+

//возможно убрать - не нужно
int CheckWay()
   {
      double HamaGreenCheck_0, HamaGreenCheck_1, HamaGreenCheck_2;
      double HamaRedCheck_0, HamaRedCheck_1, HamaRedCheck_2;
      
      //1 - Зеленая линия
      //3 - Красная линия
      HamaGreenCheck_0 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 1, 1));
      HamaGreenCheck_1 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 1, 2));
      HamaGreenCheck_2 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 1, 3));
           
      HamaRedCheck_0 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 3, 1));
      HamaRedCheck_1 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 3, 2));
      HamaRedCheck_2 = Nullifier(iCustom(NULL, 0, "HMA Color", HMA_Period, HMA_PriceType, HMA_Method, NormalizeValues, NormalizeDigitsPlus, VerticalShift, 3, 3));
           
      //Comment("HamaGreenCheck_0 = " + HamaGreenCheck_0 + "  |  HamaGreenCheck_1 = " + HamaGreenCheck_1 + "  |  HamaGreenCheck_2 = " + HamaGreenCheck_2);      
      //Comment("HamaRedCheck_0 = " + HamaRedCheck_0 + "  |  HamaRedCheck_1 = " + HamaRedCheck_1 + "  |  HamaRedCheck_2 = " + HamaRedCheck_2);
      
      if(HamaGreenCheck_0 > HamaGreenCheck_1 > HamaGreenCheck_2)
        {
          Print("Green Line 3 bars");
          return 1;
        }
      
      if(HamaRedCheck_0 < HamaRedCheck_1 < HamaRedCheck_2)
         {
            Print("Red line 3 bars");
            return 2;  
         }
         
         return 0;
   }


//проверить корень каталога на наличие файла закрытия ордера
//проверять каждый тик
string CheckCloseOrder()
  {
      string file_name = "";
      string int_dir="";
      string InpFilter="Close\\*";
      int i=1, pos=0, last_pos=-1;
   
    
      while(!IsStopped())
        {
         pos=StringFind(InpFilter,"\\",pos+1);
         if(pos >= 0)
            last_pos=pos;
         else
            break;
        }
    
      if(last_pos>=0)
         int_dir=StringSubstr(InpFilter,0,last_pos+1);
         long search_handle=FileFindFirst(InpFilter,file_name);
         if(search_handle!=INVALID_HANDLE)
            {       
               do
                 {
                     ResetLastError();
                     //--- если это файл, то функция вернет true, а если директория, то функция генерирует ошибку ERR_FILE_IS_DIRECTORY
                     FileIsExist(int_dir+file_name);
                     //Alert(file_name);
                     i++;
                 }
               while(FileFindNext(search_handle,file_name));
                  FileFindClose(search_handle);
            }      
      return(file_name);
  }


string SplitNameOrderFile(string filename_order)
   {
      string to_split = filename_order; // строка для разбивки на подстроки
      string sep="_";                // разделитель в виде символа
      ushort u_sep;                  // код символа разделителя
      string result[];               // массив для получения строк
      string splitname;
      u_sep = StringGetCharacter(sep,0);
      int k = StringSplit(to_split, u_sep, result);                 
      if(k > 0)
        {
         for(int i = 0; i < k; i++)
           {
            splitname = result[i];
           }
        }
     return splitname;
   }


void ManualCloseOrder(string Tiket)
   {
      // OP_BUY = 0 = Bid
      // OP_SELL = 1 = Ask    
      if(OrderSelect(Tiket , SELECT_BY_POS, MODE_TRADES) == True)
         {
            if(OrderType()==0)
               {
                  Print("Закрываю ордер по БИД: ");
                  OrderClose(Tiket, Lots, Bid, Slippage, Aqua);                 
               }
            
            if(OrderType()==1)
               {
                  Print("Закрываю ордер по Ask ");
                  OrderClose(Tiket, Lots, Ask, Slippage, Aqua);                  
               }
         }
   }


//Запишем файл с тикетом открытого ордера для питон-бота
void WfireOpenOrderTiket(string n_orger, string textmessage)
   {
      int filehandle = FileOpen("Open/" + n_orger, FILE_WRITE|FILE_TXT);
      FileWriteString(filehandle, textmessage);  
      FileClose(filehandle);          
   }

   
//True = new bar, False = old bar
bool CheckNewBar()                              
   {                                             
      static datetime Prev_Time=0;
      
      if(Prev_Time==0)
        {
           Prev_Time=Time[0];
           return(false);
        }
   
      if(Prev_Time!=Time[0])
        {
            Prev_Time=Time[0];
            return(true);        // Поймался новый бар
        }
        
      return(false);
   }

   
int CountSell()
   {
      int count = 0;
         for(int trade = OrdersTotal()-1; trade>=0; trade--)
            {
               if(OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)) 
                  { 
                     if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_SELL)
                        count++;
                  }
            }  
              
      return(count);
   }

   
int CountBuy()
   {
      int count = 0;
         for (int trade = OrdersTotal()-1; trade>=0; trade--)
            {
               if(OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)) 
                  { 
                     if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_BUY)
                        count++;
                  }
            }    
      return(count);
   }
      

void CloseBuy()
   {
      for(int i = OrdersTotal() - 1; i>=0; i--)
                     {
                        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
                           {
                              if(OrderMagicNumber() == Magic && OrderType() == OP_BUY)
                                 {                          
                                    //закрыть ордер на покупку
                                    OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Aqua);
                                    
                                    // удалить файл открытого ордера - если FileDelete возвратить тру - написать в лог
                                    FileDelete("Open/" + OrderTicket());                                                                   
                                 }
                           }
                     }      
   }

   
void CloseSell()
   {
       for(int i = OrdersTotal() - 1; i>=0; i--)
                  {
                     if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES))
                        {
                           if(OrderMagicNumber() == Magic && OrderType() == OP_SELL)
                              {
                                 //Закрываю ордер на продажу
                                 OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Aqua);
                                 FileDelete("Open/" + OrderTicket());
                              }
                        }
                  }//конец закрытию ордеров
   }
   
   
void OpenSell()
   {
     Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, 0, 0, "# Water #", Magic, 0, Red);    
     //WfireOpenOrderTiket(Ticket);
     
     if(Ticket > 0)
      {
         SL = NormalizeDouble(Bid + StopLoss * Point, Digits);                                   
         TP = NormalizeDouble(Bid - TakeProfit * Point, Digits);

         if (OrderSelect(Ticket, SELECT_BY_TICKET))      
            {              
               string infoorder = "Open SELL order: " + Ticket + " | " + OrderSymbol() +  " | " + OrderOpenPrice() + " | " + OrderOpenTime() + " | ";
                WfireOpenOrderTiket(Ticket, infoorder);
               if(OrderModify(Ticket, OrderOpenPrice(), SL, 0, 0) == False)
                  {
                     Print("Error modify Sell");
                  }
               else
                  Print("Error open order by SELL!");        
            }
      }
   } //end openclose


void OpenBuy()
   {
      Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, 0, 0, "# Water #", Magic, 0, Green);                     
      //WfireOpenOrderTiket(Ticket);
      
      if(Ticket > 0)
         {
            TP = NormalizeDouble(Ask + TakeProfit * Point, Digits);
            SL = NormalizeDouble(Ask - StopLoss * Point, Digits);               

           if (OrderSelect(Ticket, SELECT_BY_TICKET))
            {
               string infoorder = "Open BUY order: " + Ticket + " | " + OrderSymbol() +  " | " + OrderOpenPrice() + " | " + OrderOpenTime() + " | ";
               WfireOpenOrderTiket(Ticket, infoorder);
               
               if(OrderModify(Ticket, OrderOpenPrice(), SL, 0, 0)  == False)
                  {
                     Print("Error modify Buy!");
                  }
               else
                  Print("Error open order by Buy!");
            }
         }      
   } //end openbuy
    
    
double Nullifier(double InPut)
   {
      double Result;
         if(InPut == 2147483647.0)
            Result = 0;
         else
            Result = NormalizeDouble(InPut, Digits) ;
      return(Result);
      
   }
   
   
void TrailingOn()
   {
      for (int i = OrdersTotal() - 1; i>=0; i--)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
               {
                  if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
                     {
                        if(OrderType() == OP_BUY)
                           {
                              if(Bid - OrderOpenPrice() > TralStop*Point || OrderStopLoss() == 0)
                                 {
                                    if(OrderStopLoss() < Bid - (TralStop + TralStep)*Point || OrderStopLoss() == 0)
                                       {
                                          if(!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid-TralStop*Point, Digits), 0, 0))
                                             Print("Error modify buy order");
                                       }
                                 }
                           }
                        if(OrderType() == OP_SELL)
                           {
                              if(OrderOpenPrice() - Ask > TralStop*Point || OrderStopLoss() == 0)
                                 {
                                    if(OrderStopLoss() > Ask + (TralStop + TralStep)*Point || OrderStopLoss() == 0)
                                       {
                                          if(!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask + TralStop*Point, Digits), 0, 0))
                                             Print("Error modify sell order");
                                       }
                                 }
                           }   
                     }
               }
         }   
   }
   