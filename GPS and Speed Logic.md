# GPS and Speed Sources Defect Detection Logic
This document will be in reference to TDAT_GPS_TEMPLATE_1.xlsx. The concept, process, and logic of the spreadsheet will be described in this document.
The general construct of the spreadsheet is that specific TDAT data is ingested in Columns A though S. The ingested TDAT data fields will be compared
to other similar input values where said field values should be relatively the same and return delta values between the two input fields. These delta
values in combination with individual values will be utilized by the defect detection logic. The defect detection logic will evaluate the deltas against
defined threshold variables and return a percentage of time that the deltas were above said defined threshold variables.

## Data Ingestion
Columns A through S are data fields from TDAT file records. Note that fields are in accordance with the Available fields in Elasticsearch
Wabtec UP Team space
- *Column A*
  - record_type = all TDAT records
  - field = record_datetime

- *Column B*
  - record_type = WT1
  - field = WT1 FFPS

- *Column C*
  - ILC records where available. Not all locomotives receive ILC data. This will be an evaluated field output to determine if this speed
  source exists or not on any particular locomotive. Determination if ILC speed is an available input will determine if we will use the ILC Speed
  as part of the full
  - field = ILC FPS RAW*
    - Note that at I-ETMS software version 6.3.21.0 ILC records change from simple to complex. If complex is available, we the field need per the
  TDAT Data Dictionary TDID_PTC_ILC_SPEED instead of ILC FPS RAW

- *Columns D through K*
  - record_type = G1
  - fields
    - GPS1 FPS
    - G1 LAT
    - G1 LON
    - GPS1 ALT
    - GPS1 HDG
    - GPS1 SATS
    - GPS1 HDOP
    - GPS1 QUAL

- *Columns l through S*
  - record_type = G2
  - fields
    - GPS2 FPS
    - G2 LAT
    - G2 LON
    - GPS2 ALT
    - GPS2 HDG
    - GPS2 SATS
    - GPS2 HDOP
    - GPS2 QUAL

Currently the above are the only ingested data fields used for the defect detection logic

## ILC Data Determination
As stated previously not all locomotives where I-ETMS is applied receive ILC data from the locomotive control system. Determination if we can
expect valid ILC data will be essential for our logic as we need to know if it to use it or omit the use of it in the various speed comparisons
we will conduct. There are a couple of different ways to make this determination.

In the spreadsheet, the HAS ILC? YES/NO output is in cell AQ35. Since the data input is manual with the spreadsheet, I just look at the first 20 rows in
Column C "ILC FPS" and if any data is present = YES, else = NO. I reference this cell in later logic described in this document.

1. One way would be to grab a 2088 Onboard Component Configuration Report message from the subject locomotive to determine if ILC data can be expected
in the TDAT logs. Per WCR-SYR-1058 I-ETMS Component and Fault Data Dictionary. Section 4, Table L2I378 the following fields in that message can be used
  - Config ID: 45 "LOCO_CONTROL_SYSTEM"
The following values as received in the 2088 Message, Config ID 45 can expect tp have ILC data provided from the locomotive control system
  - LIG
  - LSI
  - LSI-ASYNC
  - ACP
  - ACP-NRZI
All other values received in the 2088 Message, Config ID 45 can be assumed that ILC data will not be provided by the locomotive control system

2. The second method could be that when the defect detection logic runs over TDAT records a specific period of time that if all of the ILC and BPI
records are written in the data with a validity value of 0, then we could assume that no ILC data is available. However this may be a poor assumption
if the LOCO_CONTROL_SYSTEM is one where we expect ILC Data and the defect root cause is a communication issue between the locomotive control system and I-ETMS.  

## Errata Columns
Column T "GPS_SIGNAL" is not currently utilized anywhere else in the logic. I started to use it where no GPS data was available and was causing errors in the
spreadsheet due to the confined structure of Excel. It does evaluate if both GPS are present or if on or both signal data is missing.
**It is possible to employ This in future revisions of the defect detection logic to evaluate how often GPS signal loss occurs.**

## Input Data Deltas
These columns are a basic comparison between two signals that in a "perfect" world should be exactly the same or at least extremely with small confidence interval.
Note that not all of these delta values are utilized in revision 1 of the logic columns described later below.

- *Column U* "G1/G2 Speed Delta"
  - Subtracts Column D "GPS1 FPS" from Column L "GPS2 FPS" and converts in to an absolute FPS value to .000 precision

- *Column V* "Lat Delta"
  - Subtracts Column E "GPS1 LAT" from Column M "GPS2 LAT" and converts into an absolute degrees value to .000000 precision
  - Additional processing of value executed in Column AC "Lat Feet Delta". See description below.
  - Currently used in downstream defect detection logic post additional processing in Column AC

- *Column W* "Lon Delta"
 - Subtracts Column F "GPS1 LON" from Column N "GPS2 LON" and converts into an absolute degrees value to .000000 precision
 - Additional processing of value executed in Column AD "Lon Feet Delta". See description below.
 - Currently used in downstream defect detection logic post additional processing in Column AD

- *Column X* "Alt Delta"
  - Subtracts Column G "GPS1 ALT" from Column O "GPS2 ALT" converts into an absolute meters value to .0 precision
  - Not used currently in downstream defect logic detection but may be used in future revisions for specific failure mode/condition detection

- *Column Y* "Heading Delta"
  - Subtracts Column H "GPS1 HDG" from Column P "GPS2 HDG" converts into an absolute degrees value to .0 precision
  - Not used currently in downstream defect logic detection but may be used in future revisions for specific failure mode/condition detection

- *Column Z* "Sat Delta"
  - Subtracts Column I "GPS1 SATS" from Column Q "GPS2 SATS" converts into an absolute whole number
  - Not used currently in downstream defect logic detection but may be used in future revisions for specific failure mode/condition detection

- *Column AA* "HDOP Delta"
  - Subtracts Column J "GPS1 HDOP" from Column R "GPS2 HDOP" converts into an absolute degrees value to .0 precision
  - Not used currently in downstream defect logic detection may but be used in future revisions for specific failure mode/condition detection

- *Column AB* "Qual Delta"
  - Subtracts Column K "GPS1 QUAL" from Column S "GPS2 QUAL" converts into an absolute whole number
  - Not used currently in downstream defect logic detection but may be used in future revisions for specific failure mode/condition detection

- *Column AC* "Lat Feet Delta"
  - Multiplies Column V "Lat Delta" by 364000 to convert the LAT degrees to feet value to .0 precision
  - Currently used in downstream defect detection logic

- *Column AD* "Lon Feet Delta"
  - Multiplies Column W "Lat Delta" by 288200 to convert the LON degrees to feet value to .0 precision
  - Currently used in downstream defect detection logic

- *Column AE* "G1/WT FPS Delta"
  - Subtracts Column B "WT1 FPS" from Column D "GPS1 FPS" converts into an absolute FPS value to .00 precision
  - Currently used in downstream defect detection logic

- *Column AF* "G2/WT FPS Delta"
  - Subtracts Column B "WT1 FPS" from Column L "GPS2 FPS" converts into an absolute FPS value to .00 precision
  - Currently used in downstream defect detection logic

- *Column AG* "G2/WT FPS Delta"
  - IF; cell AQ35 "HAS ILC?" = YES, then; Subtracts Column B "WT1 FFPS" from Column C "ILC FPS" converts into an absolute FPS value to .00 precision, else; returns 0
  - Currently used in downstream defect detection logic

## Defect Detection Logic
These columns evaluate the both Data Ingestion columns A-S and Input Data Delta columns U through AG. The returned values will produce:
- Vehicle operation based on input value combinations
- Using input variable parameters to evaluate if a defect exists for a specific input or inputs

The following sections are the first revision of the logic and may need to be tweaked so using variables that can be easily changed should be considered when coding.
I know for professional Software Engineers this is common knowledge, but I will communicate it anyway. Being an Mech Eng I have coding experience, but know just enough
to get myself into trouble...
For example if evaluating a delta such as Speed 1 vs. Speed 2 to determine if a defect exists:

>>SPD_DELTA_MAX = 4

>>def myfunc()
  SPEED_DIFF = SPD_1 - SPD_2
  ABS_SPEED_DIFF = abs(SPEED_DIFF)
  if ABS_SPEED_DIFF >= SPD_DELTA_MAX
    print("SPEED SOURCES DELTA TOO HIGH")
  else:
    print("SPEED SOURCES WITHIN TOLORANCE")

This way if we discover that the max delta value needs to be changed later the impact will be hopefully minimized.

### Column AH "MOTI-DETECT"
This column is used for a couple of reasons:
1. If no defect is detected, to describe the motion state.
2. To detect GPS defects

The concept is to evaluate all of the speed values to determine if they are above a variable speed value and then compare all of the . In Revision 1 I used 1 FPS as the
speed threshold value.
Note that the logic will be described in order of the text in the cell per TDAT_GPS_TEMPLATE_1.xlsx cell AH(X)

**First IF = True**
>>=IF(OR(AND(B3>1,C3>1,D3>1,L3>1),AND(B3>1,D3>1,L3>1),AND(C3>1,D3>1,L3>1),AND(B3>1,C3>1,OR(D3>1,L3>1))),"MOVING"*

Splitting the first IF true into its OR sections below

- *=IF(OR(AND(B3>1,C3>1,D3>1,L3>1),* if WT1 FFPS > 1 and ILC FPS > 1 and GPS1 FPS > 1 and GPS2 FPS > 1 then "MOVING"
  - Narrative; If all speed values are above a threshold variable, in this case 1 FPS, then we can assume that the locomotive is in motion or "MOVING"
  - Note; with regard to ILC FPS in the current logic, I did not provide in this cell a condition IF; cell AQ35 "HAS ILC?" = YES then run this part of the logic because
  IF; cell AQ35 "HAS ILC?" = NO we would not want to run this logic and would only want to evaluate the WT1 FFPS, GPS1 FPS and GPS1 FPS to determine if it is in motion

- *AND(B3>1,D3>1,L3>1),* or if WT1 FFPS > 1 and GPS1 FPS > 1 and GPS2 FPS > 1 then "MOVING"
  - Narrative; this one was built due to not applying the IF; cell AQ35 "HAS ILC?" = NO as it is omitting the ILC FPS. So what we could do here is evaluate the
  IF; cell AQ35 "HAS ILC?" value. If = YES then run the comparison of all four speeds being above the threshold value. If =NO then then only run the comparison of
  the three speeds (WT1 FFPS, GPS1 FPS, GPS2 FPS)

- *AND(C3>1,D3>1,L3>1),* or if ILC FPS > 1 and GPS1 FPS > 1 and GPS2 FPS > 1 then "MOVING"
   - Narrative; this one only is true if ILC data in the cell is present so if we have these three out of the four inputs > the threshold value then "MOVING"

- *AND(B3>1,C3>1,OR(D3>1,L3>1))),"MOVING",* or if WT1 FFPS > 1 and ILC FPS > 1 and GPS1 FPS > 1 or GPS2 FPS > 1 then "MOVING"
  - Narrative; if we have both WT1 and ILC speeds greater then the threshold and either GPS speed greater than the threshold, then "MOVING"

**Second IF = True**
>>IF(AND(OR(B3>1,C3>1),AND(D3<1,L3<1)),"CREEPING"

Since this IF is much smaller than the first, I will address it as a whole below

- *IF(AND(OR(B3>1,C3>1),AND(D3<1,L3<1)),"CREEPING",* if WT1 FFPS or ILC FPS > 1 and both GPS1 FPS and GPS2 FPS < 1 then "CREEPING"
  - Narrative; the wheel tachometer circuits from both the I-ETMS and ILC sources are typically very sensitive and will detect smaller movement versus GPS.
  So what happens allot of times is that if the locomotive is moving very slowly, the WT1 and ILC (if present) will read a low FPS value while GPS will have
  a zero FPS value. That is one reason why WT1 or ILC speed is I-ETMS's primary speed and location source in between GPS fixes.

**Third IF = True**
>>,IF(AND(B3<1,C3<1,L3<1,D3>1),"GPS1_HUNT",

Since this IF is much smaller than the first, I will address it as a whole below
- *IF(AND(B3<1,C3<1,L3<1,D3>1),"GPS1_HUNT",* if WT1, ILC, and GPS2 FPS are < 1 and GPS1 FPS > 1 then "GPS1_HUNT"  
  - Narrative; some GPS hardware defects and some environmental conditions display lat/lon position hunting. If the position deltas are large enough, this translates
  to a FPS value from the suspect defect GPS input since GPS speed is just a distance/time function. This should work with regards to IF; cell AQ35 "HAS ILC?" value being YES or NO
  as if we write a 0 for ILC speed if = NO, then the GPS1_HUNT condition would be detected if WT1 and GPS2 were less than 1 and GPS1 FPS was greater than the threshold value.
  - Note; We may want to add to the GPS1 and GPS2 variables a range for future capabilities as I-ETMS will determine that the WT1 is stuck at zero if GPS FPS is greater than
  a specific value for a variable period. It is not in my current revision 1 spreadsheet but is something to consider.

**Fourth IF = True**
  >>IF(AND(B3<1,C3<1,L3>1,D3<1),"GPS2_HUNT",

  Since this IF is much smaller than the first, I will address it as a whole below
  - *IF(AND(B3<1,C3<1,L3>1,D3<1),"GPS2_HUNT",* if WT1, ILC, and GPS1 FPS are < 1 and GPS2 FPS > 1 then "GPS2_HUNT"  
    - Narrative; some GPS hardware defects and some environmental conditions display lat/lon position hunting. If the position deltas are large enough, this translates
    to a FPS value from the suspect defect GPS input since GPS speed is just a distance/time function. This should work with regards to IF; cell AQ35 "HAS ILC?" value being YES or NO
    as if we write a 0 for ILC speed if = NO, then the GPS2_HUNT condition would be detected if WT1 and GPS2 were less than 1 and GPS1 FPS was greater than the threshold value.
    - Note; We may want to add to the GPS1 and GPS2 variables a range for future capabilities as I-ETMS will determine that the WT1 is stuck at zero if GPS FPS is greater than
    a specific value for a variable period. It is not in my current revision 1 spreadsheet but is something to consider.

  **Fifth IF = True and Else**
  >>IF(AND(B3<1,C3<1,D3>1,L3>1),"BOTH_GPS_HUNTING","NOT_MOVING")))))

Splitting the IF true and else into their own sections below
- *IF(AND(B3<1,C3<1,D3>1,L3>1),"BOTH_GPS_HUNTING",* if WT1 and ILC FPS < 1 and GPS1 and GPS2 FPS are > 1 then "BOTH_GPS_HUNTING"
  - Narrative; if we have both WT1 and ILC FPS values less than the threshold and GPS1 and GPS2 FPS values greater than the threshold we can assume that both GPS inputs are hunting.
  This occurs quite a bit under overpasses and where satellite reception is limited and the GPS FPS value usually is less than 4 FPS
  - However there is a flaw in this where IF; cell AQ35 "HAS ILC?"=NO, we are only actually monitoring WT1 FPS and if a defect exists where I-ETMS cannot detect the wheel tach frequency
  input, this would cause us to think that a GPS defect is occurring  while in reality it is a wheel tach issue. If I specify a range of GPS speed say between 1< and <8 I could then specify
  another IF statement for a Wheel Tach Stuck at Zero event where if WT =0 and GPS1 and GPS2 FPS > 8 then "Wheel Tach Stuck At Zero" Will wait for data returns on revision 1 before enhancing
  and becoming granular in root cause analysis.

- *"NOT_MOVING")))))* all other conditions are considered not moving for revision 1.

### Column AI "POS DELTA"
This column is used to evaluate if the two GPS positions differ by a specific amount to assist in defect detection logic.

**Only IF Statement**
>>=IF(AND(OR(AND(AC6>50,AC5>50,AC4>50,AC3>50),AND(AD6>50,AD5>50,AD4>50,AD3>50))), "DEFECT", "OK")

- *=IF(AND(OR(AND(AC6>50,AC5>50,AC4>50,AC3>50),AND(AD6>50,AD5>50,AD4>50,AD3>50))), "DEFECT", "OK")* if Lat Feet Delta or Lon Feet Delta > 50 feet over the last 4 records then defect, else no defects
  - Narrative; Set threshold of 50 feet for both LAT and LON deltas. The reasoning behind the last four samples is that I observed in the spreadsheet with locomotives as speed increased
  that I observed increasing count of false positive  POS Delta = DEFECT. This is due to GPS position processing and TDAT writing timing. Pending how we end up
  Percentage of position delta combined with other defect detection logic can assist in pinpointing GPS defects and anomalies.
  - Note; should probably scale down the lon since the feet per degree of longitude are less than feet per degree of latitude. Threshold selection needs more analysis in future revisions

### Column AJ "WT/ILC DEL"
This column is used if cell AQ35 "HAS ILC?"= YES to evaluate if a delta exists between WT1 and ILC FPS values above a variable threshold

Despite that there are two If statements, will address both together since the first if is very simple.

**Combined IF = True and Else**
>>=IF($AQ$35="YES",IF(AG2>4,"WT_ILC_DELTA","WT_ILC_OK"),"NO ILC")

- *IF($AQ$35="YES",IF(AG2>4,"WT_ILC_DELTA","WT_ILC_OK"),"NO ILC")* the first if merely determines if ILC is present as previously described. If =NO, then return "NO_ILC", if yes move to the
next if statement. Second If statement is executed if ILC =YES in previous if. If WT/ILC DEL > 4 then "WT_ILC_DELTA", else "NO DEFECT"
  - The returned value will be used by other defect logic detection cells. If there is no defect between these two values and GPS defects are detected by other cells, then we will compare both
  GPS speed values to the average of the WT1 and ILC FPS to determine which GPS is faulty. If a delta is detected between WT1 and ILC FPS and there is not a GPS Speed delta between GPS1 and GPS2 FPS values
  both WT1 and ILC FPS will be compared to the average of GPS1 and GPS2 FPS values to determine which speed input is faulty.

### Column AK "G1_G2_V_DEL"
This column is used to determine if a delta exists between GPS 1 and GPS 2 FFPS values. Very similar to column AJ "WT/ILC DEL"

**Only IF Statement**
>>=IF(U2>4,"GPS_V_DEFECT","OK")

- if the delta between GPS1 and GPS2 FPS values > 4, then "GPS_V_DEFECT", else "OK"
  - The returned value will be used by other defect logic detection cells. If there is no defect between these two GPS FPS values and a delta is found against WT1 and ILC
  If there is no defect between these two values and WT1 and ILC FPS defects are detected by other cells, then we will compare both WT1/ILC speed values to the average of the GPS1 and GPS2 FPS values to
  determine which WT1 or ILC PFS is faulty. If a delta is detected between GPS1 and GPS2 FPS values and there is not a WT1/ILC FPS values both GPS1 and GPS2 FPS values will be compared to the average of
  WT1 and ILC FPS values to determine which GPS input is faulty.
