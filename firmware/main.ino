// ######################################################################## //
//         Определения, подключение библиотек, объявление объектов          //
// ######################################################################## //

// Пины кнопок выбора теста
#define BTN_1_PIN 10
#define BTN_2_PIN 11
#define BTN_3_PIN 12

// Пины LED
#define LED_A_PIN 3
#define LED_B_PIN 5
#define LED_C_PIN 6
#define LED_D_PIN 9

// Пины кнопок для выполнения тестов
#define BTN_A_PIN 2
#define BTN_B_PIN 4
#define BTN_C_PIN 7
#define BTN_D_PIN 8

// Подключаемые библиотеки
#include <Wire.h> // работа с шиной i2c
#include <LiquidCrystal_I2C.h> // работа с дисплеем 1602

// Объявление объекта LCD - дисплей
LiquidCrystal_I2C LCD(0x27, 16, 2);


// ######################################################################## //
//                      Инициализация и главный цикл                        //
// ######################################################################## //

// Инициализация МК
void setup() {
  
  // Включение генератора случайных чисел 
  // (в качестве зерна - шум на незадействованном аналоговом пине)
  randomSeed(analogRead(0));
  
  // Включение дисплея, вывод сообщения о загрузке
  LCD.begin();
  LCD.backlight();
  LCD.print(" LOADING...");
  
  // Соединение с компьютером
  Serial.begin(9600);
  
  // Режим INPUT для кнопок выбора теста
  pinMode(BTN_1_PIN, INPUT);
  pinMode(BTN_2_PIN, INPUT);
  pinMode(BTN_3_PIN, INPUT);
  
  // Режим OUTPUT для LED
  pinMode(LED_A_PIN, OUTPUT);
  pinMode(LED_B_PIN, OUTPUT);
  pinMode(LED_C_PIN, OUTPUT);
  pinMode(LED_D_PIN, OUTPUT);
  
  // Режим INPUT для кнопок работы с тестом
  pinMode(BTN_A_PIN, INPUT);
  pinMode(BTN_B_PIN, INPUT);
  pinMode(BTN_C_PIN, INPUT);
  pinMode(BTN_D_PIN, INPUT);
  
  // Вывод на экран сообщения об успешной загрезке
  delay(1000);
  LCD.print("DONE");
  delay(1000);
  LCD.clear();
}

// Главный цикл МК
void loop() {
  
  // Вывод сообщения о выборе теста
  LCD.clear();
  LCD.print("  SELECT TEST:  ");
  LCD.setCursor(0, 1);
  LCD.print("  press button  ");

  // Сообщаем ПК - ожидание выбора теста
  Serial.println("#select");
  
  // Пока не нажата любая кнопка выбора теста
  while (true) {

    // Определение нажатой кнопки выбора теста и запуск
    // соответствующего теста  

    if (digitalRead(BTN_1_PIN) == HIGH) {test_1(); break;}
    if (digitalRead(BTN_2_PIN) == HIGH) {test_2(); break;}
    if (digitalRead(BTN_3_PIN) == HIGH) {test_3(); break;}
  }
  
}


// ######################################################################## //
//                             Процедуры тестов                             //
// ######################################################################## //

// Тест 1: испытуемому необходимо нажимать кнопки, над котороыми
// включился LED, за определенный промежуток времени (400мс)
void test_1() {
  
  // Сообщаем ПК о начале теста
  Serial.println("#test:1:800:10");
  
  // Вывод сообщения о начале теста
  LCDshowTestStartInfo(1);

  // Случайный номер LED, номер нажатой кнопки
  // соответствует светодиоду над ней (1 кнопка = 1 LED)
  byte N = 0;
  
  // Результат
  byte R = 0;
  
  // Время включения LED
  unsigned long time = 0;

  // Цикл 10 раз
  for (byte i = 0; i < 10; i++) {

    // Определение номера LED для включения (от 1 до 4)
    N = random(1, 5);
    
    // Фиксирование текущего времени
    time = millis();
    
    // Включение светодиода
    switchLED(N, HIGH);
    
    // Записать результат, если номер нажатой кнопки соответствует номеру 
    // включенного LED и время нажатия не привышает 400мс
    if (getPressedButton() == N && (millis() - time) <= 400) R++;
     
    // Сообщаем на ПК о номере попытки и времени реакции испытуемого
    Serial.print("#pass:")
    Serial.print(i+1);
    Serial.print(":");
    Serial.println(400);
    Serial.print("#plus:");
    Serial.println(millis() - time);
    
    // Выключить светодиод
    switchLED(N, LOW);
    
    // Ждать, пока испытуемый не отжал кнопку
    waitButtonsUnpressed();
    
    // Пауза перед включением следующего LED
    delay(400);
  }
  
  // Вывод результатов теста на дисплей
  LCDshowTestFinishInfo(1, R * 10);
  
  // Сообщаем ПК о результате теста
  Serial.print("#result:");
  Serial.println(R * 10);
}

// Тест 2: испытуемому необходимо нажать кнопки в том же порядке,
// в котором до этого поочередно включались светодиоды. С каждой
// новой цепочкой включений сложность увеличивается (кол-во LED)
void test_2() {
  
  // Сообщаем ПК о начале теста
  Serial.println("#test:2:limit:10:pass:5");
  
  // Вывод сообщения о начале теста
  LCDshowTestStartInfo(2);
  
  // Количество включений LED в текущей цепочке (начинается с 3)
  byte T = 2;
  
  // Результат
  byte R = 0;
  
  // Цикл 5 раз
  for (byte i = 0; i < 5; i++) {
  
    // Вывод сообщения о номере попытки
    LCDshowTry(i + 1, 5);
    
    // Сообщаем ПК о номере попытки и длине цепочки
    Serial.print("#try:");
    Serial.print(i+1);
    Serial.print(":length:");
    Serial.println(T+1);
        
    // Массив для хранения номеров LED
    // (номер первого LED записан в a[0])
    byte a[T];
    
    // Заполнение массива a случайными номерами
    for (byte j = 0; j <= T; j++) {
      
      // Запись номера LED для включения (от 1 до 4)
      a[j] = random(1, 5);
      
      // Включение соответствующего LED на короткое время
      switchLED(a[j], HIGH); delay(800);
      switchLED(a[j], LOW);  delay(800);   
    }
        
        
    // Цикл T раз (количество LED в цепочке)
    for (byte j = 0; j <= T; j++) {
            
      // Если записанный номер LED в массиве а
      // не соответствует нажатой кнопке
            
      if (a[j] != getPressedButton()) {
        
        // Сообщить об ошибке
        LCDshowError();
        
        // Выйти из цикла (перейти к следующей цепочке)
        break;
      }
      
      // Сообщаем ПК о правильном нажатии
      Serial.println("#right");

      // Если балы нажата соответствующая кнопка и 
      // цепочка была завершенна успешно (номер нажатой кнопки
      // соответствует номеру последнего LED в цепочке включений)
      // Записать результат
      if (j == T) R++;

      // Ждать, пока испытуемый не отжал кнопку
      waitButtonsUnpressed();
    }
    
    // Увеличить сложность (количество включений LED в цепочке)
    T++;
  }

  // Вывод результатов теста на дисплей
  LCDshowTestFinishInfo(2, R * 20);
  
  // Сообщаем ПК о результате теста
  Serial.print("#result:");
  Serial.println(R * 20);
  
}

// Тест 3: испытуемому необходимо нажимать кнопки в порядке 
// увиличения яркости соответствующих LED (от самого тусклого
// к самому ярком) 
void test_3() {
  
  // Сообщаем ПК о начале теста
  Serial.println("#test:3:limit:4:pass:10");
  
  // Вывод сообщения о начале теста
  LCDshowTestStartInfo(3);
  
   // Результат
  byte R = 0; 

  // Шаг смены яркости LED (255 / 4)
  byte N = 63;  

  // Яркость следующего LED  
  byte P = 0;      
    
  // Номер LED или кнопки (соответствуют)
  byte L = 0;   
  
   // Кол-во уже включенных LED
  byte turnedLEDs; 
  
  // Массив для хранения яркости каждого LED
  byte bright[4];  
  
  // Цикл 10 раз
  for (byte i = 0; i < 10; i++) {
        
    // Вывод сообщения о номере попытки
    LCDshowTry(i + 1, 10);
    
    // Сообщаем ПК о номере попытки
    Serial.print("#try:");
    Serial.println(i+1);
    
    // Яркость следующего LED (максимальная)
    P = N * 4;    
    
    // Количество включенных LED
    turnedLEDs = 0;
    
    // Обнуление значений в массиве
    for (byte j = 1; j <= 4; j++) bright[j] = 0;
    
    // Включение всех LED с разной яркостью
    // запись значения яркости в массив bright
    while (true) {
      // Определение номера LED для включения (от 1 до 4)
      L = random(1, 5);

      // Если в массиве еще нет записи о яркости LED под номером L
      if (bright[L] == 0) {
        
        // Запись яркости данного LED в массив brigh 
        bright[L] = P;
        
        // Снижение яркости для следующиего LED на шаг 
        P = P - N;
        
        // Включение данного LED с яркостью, записанной в массиве 
        analogWrite(getLEDpinByNumber(L), bright[L]);
        
        // Увеличение количества включенных LED
        turnedLEDs++;
      }
      
      // Покинуть цикл, если все LED включенны
      if (turnedLEDs == 4) break;
    }
    
    // Яркость следующиего LED равна шагу яркости (минимальная)
    P = N;
    
    // Цикл 4 раза
    for (byte j = 0; j < 4; j++) {
     
      // Определить номер нажатой кнопки
      L = getPressedButton();
    
      // Если яркость LED под номером L равна необходимой 
      if (bright[L] == P) {
        
        // Увеличить яркость, с которой должен работать 
        // следующий LED
        P = P + N;
        
        // Выключить LED
        switchLED(L, LOW);
        
        // Сообщаем ПК о правильном нажатии кнопки
        Serial.println("#right");
        
        // Если была нажата последнаяя кнопка, номер которой
        // соответствует LED с максимальной яркостью
        // Записать результат
        if (j == 3) R++;
        
      // Если яркость LED под номером L не соответствует 
      // необходимой яркости P 
      } else {
        
        // Вывести сообщение об ошибке на дисплей
        LCDshowError();
        
        // и покинуть цикл 
        break;
      }

      // Ждать, пока испытуемый не отжал кнопку
      waitButtonsUnpressed();
    }
 
    // Выключение всех LED
    for (byte j = 1; j <= 4; j++) switchLED(j, LOW);
  }
  
  // Вывод результатов теста на дисплей
  LCDshowTestFinishInfo(3, R * 10);
  
  // Сообщаем ПК о результате теста
  Serial.print("#result:");
  Serial.println(R * 10);
}


// ######################################################################## //
//                    Работа со светодиодами и кнопками                     //
// ######################################################################## //

// Изменить состояние LED (включить / выключить)
void switchLED(byte ledNumber, boolean state) {
  
  // Получить номер пина и изменить его состояние
  digitalWrite(getLEDpinByNumber(ledNumber), state);
  
}

// Определение пина, к которому подключен LED с указанным номером 
byte getLEDpinByNumber(byte ledNumber){
  
  // Выбор возможного номера LED, возврат номера пина
  switch (ledNumber) {
    case 1: return LED_A_PIN;
    case 2: return LED_B_PIN;
    case 3: return LED_C_PIN;
    case 4: return LED_D_PIN;
  }
}

// Ожидание пока все кнопки не будут отжаты
void waitButtonsUnpressed() {
  
  // Номер кнопки (1 для запуска цикла)
  int L = 1;
  
  // Пока нажата какая-либо кнопка, выполнять цикл
  while (L != 0) {
    
    // Номер нажатой кнопки (0 для выхода из цикла)
    L = 0;
    
    // Записать в L номер нажатой кнопки
    // если не будет нажата ни одна кнопка 
    // в L сохранится 0 и процедура завершится
    if (digitalRead(BTN_A_PIN) == HIGH) L = 1;
    if (digitalRead(BTN_B_PIN) == HIGH) L = 2;
    if (digitalRead(BTN_C_PIN) == HIGH) L = 3;
    if (digitalRead(BTN_D_PIN) == HIGH) L = 4;
    
  }
  
}

// Получить номер нажатой кнопки
byte getPressedButton() {
  
  // Цикл, пока не нажата ни одна кнопка
  while (true) {
    
    // Если нажата одна из кнопок - вернуть ее номер 
    if (digitalRead(BTN_A_PIN) == HIGH) return 1;
    if (digitalRead(BTN_B_PIN) == HIGH) return 2;
    if (digitalRead(BTN_C_PIN) == HIGH) return 3;
    if (digitalRead(BTN_D_PIN) == HIGH) return 4;
  }

}


// ######################################################################## //
//                     Работа с сообщениями на дисплее                      //
// ######################################################################## //

// Вывод сообщения о начале теста
void LCDshowTestStartInfo(byte testNumber) {
    
  // Вывод номера теста и сообщение о начале готовности
  LCD.print("  press button  ");
  LCD.clear();
  LCD.print("     TEST ");
  LCD.print(testNumber);
  LCD.setCursor(0, 1);
  LCD.print("    ready:");
  
  // обратный отсчет
  LCD.setCursor(11, 1); LCD.print("3"); delay(1000);
  LCD.setCursor(11, 1); LCD.print("2"); delay(1000);
  LCD.setCursor(11, 1); LCD.print("1"); delay(1000);
  LCD.setCursor(0, 1);  LCD.print("     start! "); delay(500);
  LCD.setCursor(0, 1);  LCD.print("            "); delay(500);

}

// Вывод сообщение о завершении теста
void LCDshowTestFinishInfo(byte testNumber, byte result) {
  
  LCD.clear();
  LCD.print("     TEST ");
  LCD.print(testNumber);
  LCD.setCursor(0, 1);
  LCD.print("Result: ");
  LCD.print(result);
  LCD.print("%");
  delay(4000);
  
}

// Вывод сообщения о номере попытки
void LCDshowTry(byte tryNumber, byte tryCount) {
  
  LCD.setCursor(0, 1);
  LCD.print("Try: "); LCD.print(tryNumber);
  LCD.print("/");     LCD.print(tryCount);
  delay(1000);
  LCD.setCursor(0, 1);
  LCD.print("             ");

}

// Вывод ообщения об ошибке
void LCDshowError() {
  
  LCD.setCursor(0, 1);
  LCD.print("Error!");
  delay(500);
  LCD.setCursor(0, 1);
  LCD.print("      ");

}








