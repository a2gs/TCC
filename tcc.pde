/****************************************************************
 *                                                              *
 * TCC - Elevador de Assistencia para Cadeirantes em Automóveis *
 *                                                              *
 * FEI - Faculdade de Engenharia Industrial / SBC-2013          *
 *                                                              *
 * Alzira Andrade                   12.103.384-9                *
 * Andre Augusto Giannotti Scota    12.105.234-4                *
 * Gustavo Andretta                 12.204.246-8                *
 * Messias Seliguim                 12.204.252-6                *
 * Thiago Munhoz                    12.204.172-6                *
 *                                                              *
 * By persistence! Yesterday, Today and Forever!                *
 *                                                              *
 ****************************************************************/


/*

                      Sensores
Sensor 2              1 do Motor 2 e
do Motor 2            2 do Motor 1
#>------------------------<##
      Trilho horizontal     V
                            |
                            |
                            | Trilho vertical
                            |
                            |
                            A
                            #
                        Sensor 1 do
                        Motor 1


#	Sensor n
A	Acionamento do motor 1 rele 1 - SUBIR
V	Acionamento do motor 1 rele 2 - DESCER
<	Acionamento do motor 2 rele 1 - RECOLHER PRANCHA
>	Acionamento do motor 2 rele 2 - LIBERAR PRANCHA

*/


/*

POWER ON{

   PARTE DO CODIGO DE STARTUP{
      /- Caso o sistema for ligado e o sensor da porta indicar 'porta aberta',
         tentará recolher o elevador. Depois irá para o loop eterno.
         Provavelmente entrará neste caso apos acionar botao de panico
         ou um shutdown nao programado (o elevador parou no meio do caminho,
         nao recolhido)
       -/
      se(SENSOR PORTA ESTA INDICANDO PORTA ABERTA){
         faça(ate o fim da ultima instrução, seja lá quanto tempo demorar){
            Acionar motor 1 para 'subir' ate sensor A indicar fim de curso
            Acionar motor 2 para 'recolher' ate sensor A indicar fim de curso
         }
      }

      /- Caso o sistema for ligado com o sensor da porta indicando 'porta fechada',
         quer dizer que o elevador já está recolhido e nao faz nada e vai
         pro loop eterno.
         Este estado poderá ser visto se um dos sensores do motor1
         estiver indicando fim de curso e outro sensor do motor2 tambem estiver
         indicando fim de curso.
       -/
   }

   LOOP ETERNO{

      se(SENSOR PORTA ESTA INDICANDO PORTA ABERTA){

         se(BOTAO "QUERO FALAR" ESTIVER PRESSIONADO){
            Acende o LED "Pode falar"
            Captura comando do RECONHECIMENTO DE VOZ (comando falado)
            Apaga o LER "Pode falar"
        }


        se(COMANDO FALADO É "SUBIR"){
            faça(ate o fim da ultima instrução, seja lá quanto tempo demorar){
                Acionar motor 1 para 'subir' ate sensor A indicar fim de curso
                Acionar motor 2 para 'recolher' ate sensor A indicar fim de curso
            }
        }

        se(COMANDO FALADO É "DESCER"){
            faça(ate o fim da ultima instrução, seja lá quanto tempo demorar){
                Acionar motor 2 para 'por pra fora' ate sensor B indicar fim de curso
                Acionar motor 1 para 'descer' ate sensor B indicar fim de curso
            }
        }

        se("BOTAO PANICO" ATIVADO){
            faça(eternamente){
                travar motor 1 (acionar relés 'subir' e 'descer' juntos)
                travar motor 2 (acionar relés 'recolher' e 'por pra fora' juntos)
            }
        }
    }
}

*/


#define SIMULACAO (1)  // Serial usada como log (0) ou kit de reconhecimento conectado (1)

typedef enum{
  UNKNOW,
  SUBIR,
  DESCER,
  PARAR
}comando_t;

comando_t COMANDO; // Comando a ser executado
int VOZ_CMD; // Comando lido do kit de reconhecimento de voz
int FIM_DE_MOVIMENTO; // Indica se fez o movimento completo


void setup()
{
  COMANDO = UNKNOW;
  VOZ_CMD = 0;

  pinMode(2, OUTPUT); // LED "Pode falar"
  pinMode(4, OUTPUT); // Rele 1 Motor 1 - SUBIR
  pinMode(5, OUTPUT); // Rele 2 Motor 1 - DESCER
  pinMode(8, OUTPUT); // Rele 1 Motor 2 - RECOLHER PRANCHA
  pinMode(9, OUTPUT); // Rele 2 Motor 2 - LIBERAR PRANCHA

  pinMode(3, INPUT);  // Switch "Quero falar"
  pinMode(6, INPUT);  // Sensor 1 Motor 1
  pinMode(7, INPUT);  // Sensor 2 Motor 1
  pinMode(10, INPUT); // Sensor 1 Motor 2
  pinMode(11, INPUT); // Sensor 2 Motor 2
  pinMode(12, INPUT); // Sensor porta
  pinMode(13, INPUT); // Switch "PANICO"

  // Push-up
  digitalWrite(3, HIGH);
  digitalWrite(6, HIGH);
  digitalWrite(7, HIGH);
  digitalWrite(10, HIGH);
  digitalWrite(11, HIGH);
  digitalWrite(12, HIGH);
  digitalWrite(13, HIGH);

  // Serial
#ifdef SIMULACAO
  Serial.begin(9600);
#else
  // TODO: Inicializacao do kit de reconhecimento de voz
#endif

  delay(50); // Por seguranca, delay para a estabilidade das portas

  /*
   * Iremos colocar o sistema na inicializacao correta: prancha completamente recolhida.
   * O sistema pode ter sido desligado abruptamente ou o botao de PANICO foi acionado.
   */


  //Se a porta estiver aberta, recolher pracha
  if(digitalRead(12) == HIGH){
#ifdef SIMULACAO
    Serial.print("DEFININDO POSICAO INICIAL!\n");
#endif

    // Acionaremos MOTOR 1 ate disparar sensor 2
    ACIONA_MOTOR(4, 7);

    delay(1000);

    // Acionaremos MOTOR 2 ate disparar sensor 2
    ACIONA_MOTOR(8, 11);
  }
}


void PANICO(void)
{
  while(1){
    // Acionando todos os motores!!
    digitalWrite(4, HIGH); digitalWrite(5, HIGH);
    digitalWrite(8, HIGH); digitalWrite(9, HIGH);
  }
}


void DESLIGAR_TUDO(void)
{
  digitalWrite(4, LOW); digitalWrite(5, LOW);
  digitalWrite(8, LOW); digitalWrite(9, LOW);
}


/*
 * Aciona o motor MOTOR ate sensor SENSOR ir para nivel logico diferente de LOW
 */
void ACIONA_MOTOR(int MOTOR, int SENSOR)
{
  while(digitalRead(SENSOR) != LOW){
    digitalWrite(MOTOR, HIGH); // Acionando motor para "liberar prancha"

    // Se o botal do PANICO FOI ACIONADO
    if(digitalRead(13) == LOW){
      PANICO();
    }
  }

  digitalWrite(MOTOR, LOW);
}


void loop()
{
  // Se a porta esta aberta
  if(digitalRead(12) == HIGH){
#ifdef SIMULACAO
    Serial.print("Porta aberta\n");
#endif

    // Se o botal do PANICO FOI ACIONADO
    if(digitalRead(13) == LOW){
#ifdef SIMULACAO
      Serial.print("PANICO!\n");
#endif
      PANICO();
    }

    // Se o botao de "Quero falar" estiver pressionado
    if(digitalRead(3) == LOW){

      // Ascende LED "Pode falar"
      digitalWrite(2, HIGH);

#ifdef SIMULACAO
      Serial.print("Esperando comando de voz valido\n");

      while(1){

        if(Serial.available() > 0){

          VOZ_CMD = Serial.read();

          Serial.print("Valor lido: \n");
          Serial.print(VOZ_CMD, DEC);

          if(VOZ_CMD == '1'){

              COMANDO = SUBIR;
              break;

          }else if(VOZ_CMD == '2'){

              COMANDO = DESCER;
              break;

          }else if(VOZ_CMD == '3'){

              COMANDO = PARAR;
              break;

          }else{

            // Comando nao reconhecido. Pisca LED e le proximo byte
            digitalWrite(2, LOW); delay(60); digitalWrite(2, HIGH); delay(60);
            digitalWrite(2, LOW); delay(60); digitalWrite(2, HIGH); delay(60);
            digitalWrite(2, LOW); delay(60); digitalWrite(2, HIGH); delay(60);
            digitalWrite(2, LOW); delay(60); digitalWrite(2, HIGH); delay(60);
            continue;

          }
        }
      }

#else
      // TODO: while(1){ LE COMANDO DO RECONHECIMENTO DE VOZ E DEFINE VARIAVEL "COMANDO" }
#endif

      FIM_DE_MOVIMENTO = 0;

      Serial.flush();

      // Apaga LED "Pode falar"
      digitalWrite(2, LOW);

      delay(700);

    }

    if(FIM_DE_MOVIMENTO == 0){

      switch(COMANDO){

        case SUBIR: // "subir" e "recolher prancha"

#ifdef SIMULACAO
          Serial.print("SUBIR!\n");
#endif

          // Por seguranca, vamos desativar os 2 motores
          DESLIGAR_TUDO();

          // Acionaremos MOTOR 1 ate disparar sensor 2
          ACIONA_MOTOR(4, 7);

          delay(1000);

          // Acionaremos MOTOR 2 ate disparar sensor 2
          ACIONA_MOTOR(8, 11);

          FIM_DE_MOVIMENTO = 1;

          break;

        case DESCER: // "liberar pracha" e "descer"

#ifdef SIMULACAO
          Serial.print("DESCER!!\n");
#endif

          // Por seguranca, vamos desativar os 2 motores
          DESLIGAR_TUDO();

          // Acionaremos MOTOR 2 ate disparar sensor 1
          ACIONA_MOTOR(9, 10);

          delay(1000);

          // Acionaremos MOTOR 1 ate disparar sensor 1
          ACIONA_MOTOR(5, 6);

          FIM_DE_MOVIMENTO = 1;

          break;

        case PARAR:

          // Desligamos todos os motores
          DESLIGAR_TUDO();

          break;

        default:

          // Por seguranca, vamos desativar os 2 motores
          DESLIGAR_TUDO();

          break;

      } // switch

    }

  }else{

#ifdef SIMULACAO
    Serial.print("Porta fechada\n");
#endif

  }

}
