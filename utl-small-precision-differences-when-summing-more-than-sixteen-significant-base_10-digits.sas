Small precision differences when summing more than sixteen significant base 10 digits

  We need 128 byte floats

  Problem

    When shifting 10 base 10 digits programatically left the digits do not remain tha same?

  There are several issues when dealing with base10 in a binary world

     1. The intermediate numbers cannot be represented exacty in IEE floats exactly, summing futhwe complcates this.

             BIG*10**10 + small  = 1234567890.1234567890123456  (if exact)

     2.  I think it has to do with order of operations and complex cpu rounding rules
     3.  I expect different results in Unix and Mainframe.
     4.  I suspect interative DIGIT10=DIGIT12 may maintain a different precision than iterative 'DIGIT12=BIG*2**33+SMALL';


 SAME RESULTS IN SAS AND R

  SAS
    DIGIT12    494043279331
    DIGIT10    4940432841           ** do not match
    DIFF              562           ** difference

  R  ( iterative)
    DIGIT10    510797249027
    DIGIT12    5107972539          ** do not match
    DIFF               49          ** difference

  R (matrix solution - no looping)
    DIGIT10    495075944526
    DIGIT12    4950759495          ** do not match
                       50          ** difference

  SAS More precise
    DIGIT10    494043279332.43011
    DIGIT12    4940432840.43011
    DIFF               47           ** difference

  SAS Exact
    DIGIT10    9999999999
    DIGIT12     100000000           ** exact (not the rounding)
    DIFF                0           ** uses a pseudo binary power distribution

  METHODS AND SOLUTIONS

       a. Original problem
       b. Better precision
       c. Exact (related problem uniform does not have exact float representation)
       d. R (iterative)
       e. R (no loop)

     You are summing 100 values like

             1234567890.123456789012345

     Cannot be represented by a 64bit float.

     If you convert to a binary problem you can get exact answers

         Note 10**10 and 10**8 are represented exactly in binary
         Uniform numbers in binary are 2**(-1), 2**(-2) ...

*                     _       _             _
  __ _      ___  _ __(_) __ _(_)_ __   __ _| |
 / _` |    / _ \| '__| |/ _` | | '_ \ / _` | |
| (_| |_  | (_) | |  | | (_| | | | | | (_| | |
 \__,_(_)  \___/|_|  |_|\__, |_|_| |_|\__,_|_|
                        |___/
;

DATA have;
  DO I=1 TO 100;
    BIG=RANUNI(123456);
    SMALL=RANUNI(654321);
    DIGIT12 =BIG*10**10 + small;
    DIGIT10 =BIG*10**8  + small;
    DIGIT10x=DIGIT12;
    OUTPUT;
  END;
RUN;

PROC MEANS DATA=have NOPRINT NWAY;
  format _numeric_ 16.0;
  VAR small DIGIT12 DIGIT10 digit10x;
  OUTPUT OUT=want(drop=_:) SUM=;
RUN;

PROC PRINT DATA=want;
RUN;

      DIGIT12             DIGIT10            DIGIT10X

 494043279331          4940432841        494043279331

*_                                                       _
| |__     _ __ ___   ___  _ __ ___   _ __  _ __ ___  ___(_)___  ___
| '_ \   | '_ ` _ \ / _ \| '__/ _ \ | '_ \| '__/ _ \/ __| / __|/ _ \
| |_) |  | | | | | | (_) | | |  __/ | |_) | | |  __/ (__| \__ \  __/
|_.__(_) |_| |_| |_|\___/|_|  \___| | .__/|_|  \___|\___|_|___/\___|
                                    |_|
;

DATA have;
  DO I=1 TO 100;
    BIG=RANUNI(123456);
    SMALL=RANUNI(654321);
    DIGIT12=round(BIG*10**10,1);
    DIGIT10=round(BIG*10**8,1);
    DIGIT10x=DIGIT12;
    OUTPUT;
  END;
RUN;


PROC MEANS DATA=have NOPRINT NWAY;
  format _numeric_ 16.0;
  VAR small DIGIT12 DIGIT10 digit10x;
  OUTPUT OUT=havSum SUM=;
RUN;


data want;
    set havSum;
    DIGIT12c=cats(int(digit12+int(small)),'.',int(100000*(mod(small,1))));
    DIGIT10c=cats(int(digit10+int(small)),'.',int(100000*(mod(small,1))));
    DIGIT10xc=cats(int(digit10x+int(small)),'.',int(100000*(mod(small,1))));
    keep DIGIT12C DIGIT10C DIGIT10XC ;
run;quit;


      DIGIT12C             DIGIT10C            DIGIT10XC

 4940432 793 32.43011    4940432840.43011    494043279332.43011

*                             _
  ___      _____  ____ _  ___| |_
 / __|    / _ \ \/ / _` |/ __| __|
| (__ _  |  __/>  < (_| | (__| |_
 \___(_)  \___/_/\_\__,_|\___|\__|

;

DATA have;
  DO I=1 TO 33;
    BIG=2**(-i);
    SMALL=2**(-32+1);
    DIGIT12 =round(BIG*10**10);
    DIGIT10 =round(BIG*10**8) ;
    DIGIT10x=DIGIT12;
    OUTPUT;
  END;
RUN;

PROC MEANS DATA=have NOPRINT NWAY;
  format _numeric_ 16.0;
  VAR small DIGIT12 DIGIT10 digit10x;
  OUTPUT OUT=havSum SUM=;
RUN;

data want;
    set havSum;
    DIGIT12c=cats(int(digit12+int(small)),'.',int(100000*(mod(small,1))));
    DIGIT10c=cats(int(digit10+int(small)),'.',int(100000*(mod(small,1))));
    DIGIT10xc=cats(int(digit10x+int(small)),'.',int(100000*(mod(small,1))));
    keep DIGIT12C DIGIT10C DIGIT10XC ;
run;quit;

PROC PRINT DATA=want;
format _numeric_ 16.;
RUN;
*    _            _ _
  __| |    _ __  (_) |_ ___ _ __
 / _` |   | '__| | | __/ _ \ '__|
| (_| |_  | |    | | ||  __/ |
 \__,_(_) |_|    |_|\__\___|_|

;

%utl_submit_r64('
  library(stats);
  library(data.table);
  digit12<-0;
  digit10<-0;
  digit1012<-0;
  for (i in 1:100) {
       small<-runif(1);
       big <-runif(1);
       digit12   <- digit12 + big*10**10 + small;
       digit10   <- digit10 + big*10**8  + small;
       digit1012 <- digit12;
  };
  digit10;
  digit1012;
  };
');


[1] 5107972539
[1] 510797249027

*                     _
 _ __   _ __   ___   | | ___   ___  _ __
| '__| | '_ \ / _ \  | |/ _ \ / _ \| '_ \
| |    | | | | (_) | | | (_) | (_) | |_) |
|_|    |_| |_|\___/  |_|\___/ \___/| .__/
                                   |_|
;


%utl_submit_r64('
  library(stats);
  library(data.table);
  SMALL<-runif(100);
  BIG<-runif(100);
  DIGIT12 <-sum(BIG*10**10+SMALL);
  DIGIT10 <-sum(BIG*10**8+SMALL);
  DIGITTEN<-DIGIT12;
  want<-as.data.table(round(cbind(DIGIT12, DIGIT10 ,DIGITTEN)));
  want;
');



