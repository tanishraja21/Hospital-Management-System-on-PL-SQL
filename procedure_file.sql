drop sequence prescription_sequence;
drop sequence message_sequence;
drop SEQUENCE messages;
drop sequence admission_next;
drop sequence patinet_next;
drop sequence msg_nex;
drop sequence dischargemessage;

Create or replace type ListOfDrugs as varray(50) of varchar(500); 


create sequence dischargemessage start with 16;
create sequence admission_next start with 500; 
create sequence msg_next start with 600; 
create sequence patinet_next start with 160; 
CREATE SEQUENCE messages START WITH  10;
create sequence prescription_sequence minvalue 0 start with 9 INCREMENT BY 1;
create sequence message_sequence minvalue 0 start with 3 INCREMENT BY 1;



DROP PROCEDURE Add_new_patient;
DROP PROCEDURE Admit_patient;
DROP PROCEDURE ASSIGN_ROOM;
DROP PROCEDURE Treatment_add;
DROP PROCEDURE Patient_DrugAllergy;
DROP PROCEDURE Prescribe_a_drug;
DROP PROCEDURE nurse_patient_details;
DROP PROCEDURE discharge_patient;
DROP PROCEDURE contact_tracing;
DROP PROCEDURE room_stat;
DROP PROCEDURE shift_statistics;
DROP PROCEDURE Re_admission;


---Feature 1 and 2

---1st feature


Create or replace 
	PROCEDURE Add_new_patient(patientname in varchar, gen_der in varchar, DOB in date, add_ress varchar, pho_ne number, email varchar) IS
    
    check_p int;
    
    begin
    select count(*) into check_p from patient where pname=patientname and pdob=DOB; --checking patinet
    
    if (check_p=1) 
    then 
      dbms_output.put_line('Patient Alredy Exists'); 
      update patient set paddress=add_ress, p_email=email,p_phonenumber=pho_ne  --if the patient is present then update
      where pname=patientname and pdob=DOB;
      
    else
      insert into patient values 
      (patinet_next.nextval,patientname, gen_der, DOB, add_ress, pho_ne, email);  --inserting the values in patinet table
      dbms_output.put_line('Newly Assigned Patient ID is'); 
      dbms_output.put_line(patinet_next.nextval); 
    
end if;
    end;
    /
    ---------------------------------------------------------------------------
 
 --feature 2nd   
Create or replace 
	PROCEDURE Admit_patient(patientname in varchar, DOB in date, h_id int, d_id int, reason varchar) IS
       
   check_p int;
   check_h int;
   check_dh int;
   p_id int;
   doc_name varchar(20);
   hos_name varchar(20);
   xyz varchar(100);
    begin
    ---checking for given patient
   
   select count(*) into check_p from patient where pname=patientname and pdob=DOB; 
   xyz:='Error:Invalid Patient';
   select pid into p_id from patient where pname=patientname and pdob=DOB;  ---checking if the patinet is present or not
    
   xyz:='Error: Invalid Doctor';
   select dname into doc_name from doctor
   where did=d_id;                                ---retriving the doctor name with respect to DID
   
   xyz:='Error: Invalid Hospital';
   select hname into hos_name from hospital
   where hid=h_id;                                 ---retriving the hospital name with respect to HID
    
    if check_p=0
    then
        dbms_output.put_line('Error:Invalid Patient');  
    else  
            
              select count(*) into check_h from hospital where hid=h_id;  ---checking whether hospital is present or not
          if check_h=0
          then
                dbms_output.put_line('Error:Input hospital ID is not valid');   
          else 
                    
                             select count(*) into check_dh from doctor d, hospital h  ---checking whether doctor is present or not
                              where d.hid=h.hid and d.did=d_id;
                    if check_dh=0
                    then
                          dbms_output.put_line('Error:No Doctor with given Id affiliated to any hospital');
                    else
                              insert into admission values               ----inserting values into admission table
                              (admission_next.nextval,d_id,146,systimestamp,null,111,null,'admitted waiting for a room','ENT Check Up',p_id,h_id);
              
                    end if;
          end if;  
    
    end if;
    
    
    insert into message values        ----inserting values into message table
    (msg_next.nextval,'Dr. ' || doc_name || ' Patient ' || patientname || ' has been admitted into hospital ' ||hos_name ,systimestamp,p_id,d_id);
    
    
    exception                                             ----exception handling for data_not_found
    when no_data_found then
    dbms_output.put_line('Error: Data is not present in the database'||xyz);
    end;
	/
-----------------------------------------------------------
---------------feature 3

CREATE OR REPLACE PROCEDURE assign_room(  
A_ID IN INT,
STRT IN TIMESTAMP,
STP IN TIMESTAMP,
r_type IN VARCHAR2)
IS 
l_count number;
r_count number;

ADM ADMISSION.aid%TYPE;
room_1 ADMISSION_ROOMS.rid%TYPE;
room_loc ROOM.ROOM_LOCATION%TYPE;
P_ID ADMISSION.pid%TYPE;
D_ID ADMISSION.did%TYPE;
PNAME1 PATIENT.pname%TYPE;

BEGIN

  SELECT count(*) INTO l_count FROM ADMISSION WHERE aid = A_ID; --check whether aid is present

  IF( l_count > 0 ) – check whether aid is present or not
  
  THEN
  

    SELECT a.aid, a.pid, a.did,p.pname INTO ADM,P_ID, D_ID,PNAME1 FROM ADMISSION a,patient p WHERE aid = A_ID and p.pid=a.pid; -- values found
    


    SELECT count(*) INTO r_count FROM admission_rooms a, room r WHERE a.aid = A_ID and r.ROOM_TYPE = r_type; -- room type 

    IF r_count > 0 THEN -- check whether the room type admission is available or not
        
        select rid into room_1 from admission_rooms where start_time <= stp and  end_time >= strt and aid = A_ID; 

   
        Dbms_output.put_line(room_1);
        select room_location into room_loc from ROOM where rid =room_1; 
        Dbms_output.put_line('Room ID: ' || room_1 || ' Room Location: ' || room_loc);-- print roomid and room location 
      
    
       insert into message1 values(messages.nextval, ( 'Room'||room_1 ||'has been assigned to' || PNAME1  || 'from' || strt  ||'to' || stp), SYSTIMESTAMP , P_ID,d_id);
    
        update admission set admit_status = 'admitted' where aid = a_id;  
    ELSE
        DBMS_OUTPUT.PUT_LINE('NO ROOMS ARE AVAILABLE');

    END IF;    
    

ELSE 
    DBMS_OUTPUT.PUT_LINE('NO SUCH ID EXISTS');
END IF;

Exception
        when no_data_found then
        Dbms_output.put_line('no rows found');
        
        when too_many_rows then
        dbms_output.put_line('too  many rows');
END;
----------------------------------------------------------------------------------

-------Feature 4 and 5 

---4th feature-----------------

set serveroutput on;
create or replace procedure Treatment_add(n_admission_id in int, n_treatment_id in int,n_treatment_date in date)
IS
v_treatment_id int;   ------------ valid treatment id---------------------------
v_admission_id int;     --------------------- valid admission id-----------------------------
ad_patient_id int;  ------------------------- admit patient id ------------------
ad_doctor_id int; ---------------------------------- admit doctor id ----------------
t_treatment_name varchar(256);   ----------- treatment name------------
patient_name varchar(250);
v_did int;
v_pid int;
v_msgtime timestamp;
v_pname varchar(250);
v_tname varchar(250);
v_tdate date;
MessageBody varchar(250);
Begin
select count(*) into v_treatment_id from Treatment where tid = n_treatment_id; 
if v_treatment_id = 0 then
    dbms_output.put_line('invalid treatment ID');  ----------- Step 1 This procedure will first check whether the patient ID is valid. If it is not valid, print out an error message and stop.---
    return;
else
        select count(*) into v_admission_id from admission where aid = n_admission_id;
        if v_admission_id = 0 then
        dbms_output.put_line('invalid admission ID'); ---- Step 2 It then loops through each drug ID in the array, and checks whether each drug ID is valid, if it is not valid, print a message the drug ID is not valid and skip that drug ID------ 
        return;
        else
        select pid,did into ad_patient_id, ad_doctor_id from admission where aid = n_admission_id;
        select pname into patient_name from patient where pid = ad_patient_id;
        select tname into t_treatment_name from treatment where tid = n_treatment_id;
        insert into admission_treatment values (n_admission_id,n_treatment_id,n_treatment_date); --- Step 3 If the drug ID is valid, it will check whether the pair of patient ID, drug ID is already in the drug_allergy table. If so print a message 'already inserted' and skip this drug ID-----
MessageBody:='patient' || v_pname || 'received' || v_tname || 'on' || v_tdate;
insert into message values(mid_sequence.nextval,Messagebody,v_msgtime,v_pid,v_did);  

end if;
    end if;
end;
/

------------5th feature-----------------------------

create or replace procedure Patient_DrugAllergy (PatientID int , List_of_Drugs1 ListOfDrugs)
AS
n_count int;
count_drug int; ----initializing drug count---
a_id int; 
DName varchar(50); -----drug name----
id_allergy int; ------- initializing variable for drug allergy id--------
BEGIN 
 select count(*) into n_count from Patient P where  P.PID = PatientID;
  if n_count = 0 then 
   dbms_output.put_line('Invalid patient id'); ---- Step 1 This procedure first checks whether the treatment ID is valid. If it is not, print an error message and stop.  ------
 else
   for i in 1..List_of_Drugs1.count loop
   a_id := TO_NUMBER(List_of_Drugs1(i));
   select count(*) into count_drug from Drug D where  D.drug_id = a_id;
   if count_drug = 0 then
    dbms_output.put_line(i||' is Invalid drug ID '); ----- Step 2 It then checks whether the admission ID is valid. If it is not, print an error message and stop-------
    else
     Select count(*) into n_count from Drug_allergy A where A.PID=PatientID and A.drg_alg_id = a_id; ------fetching count from drug_allergy table
     if n_count = 0 then
      Select max(drg_alg_id) into id_allergy from drug_allergy;-------- fetching maximum count from drug_allergy table---------
      if id_allergy is null then
       id_allergy := 0;
       end if;
       insert into drug_allergy values(id_allergy+1,PatientID,a_id); ------ It then inserts a row into admission_treatment table, with given admission ID, treatment ID and date. 
       Select drug_name into DName from drug where drug_id=TO_NUMBER(i);
       dbms_output.put_line('Allergy to drug '||DName||' is recorded');
     else
if n_count > 0 then
       dbms_output.put_line('already inserted'); ----------if the row already there shows it is inserted-------------
   end if;
   end if;
   end if;
  end loop; 
   end if;
end;
/


-----------------------------------------------------------
--feature 6

create or replace procedure Prescribe_a_drug(
DrugId in drug.drug_id%TYPE,
AdmissionId in admission.aid%TYPE,
Prescriptiondate in prescription.prescription_date%TYPE,
Number_of_Days in prescription.Number_of_Days_drug%TYPE,
Number_ofRefills in prescription.Number_of_Refills%TYPE
)
as
Drug_existence number:=0;
Admission__existence  number :=0;
PatientName varchar(50);
Doctorid number;
DrugName varchar(50);
PatientId number;
v_count number;
message varchar(100);
p varchar(100);
Begin
select count(*) into v_count from drug_Allergy where pid=patientid and drg_alg_id=DrugId;
select count(*) into Drug_existence from Drug d where d.drug_id=DrugId;
if Drug_existence = 0 then 
dbms_output.put_line('Invalid Drug Id');
else
dbms_output.put_line('Drug Id is valid');
select count(*) into Admission__existence from Admission where aid=AdmissionId;
if Admission__existence = 0 then 
dbms_output.put_line('Invalid Admission Id');
else
dbms_output.put_line('Admission Id is valid');
select a.pid, a.did,p.pname into Patientid, Doctorid,p  from admission a, patient p where a.aid = AdmissionId and a.pid=p.pid;
select drug_name into DrugName from Drug where drug_id = DrugId;
if v_count <> 0 then
dbms_output.put_line('Patient'|| p || ' is allergic to' || DrugName || ', choose another drug');
else 
dbms_output.put_line('Patient '|| p || ' is not allergic to ' || DrugName);
insert into prescription values(601, DrugId, AdmissionId, Prescriptiondate, Number_of_Days, Number_ofRefills);
insert into message values(203,'A new prescription of ' || DrugName || ' is created',SYSTIMESTAMP,PatientId,Doctorid);
end if;
end if;
end if;
exception when no_data_found then dbms_output.put_line('no data exists'); 
end;

/
-----------------------------------------------------------------------------------
----Feature 7 and 8

--FEATURE 7 & 8

SET SERVEROUTPUT ON;
---Feature 7 nurse assigned to rooms and patients ----
create or replace 
    procedure nurse_patient_details(n_id in int, curtime in timestamp)
As
    ncount int;
    Cursor C1 is select s.rid, r.room_location, p.pname from patient p, room r, admission a, shifttable_nurse s, admission_rooms ar
    where a.aid=ar.aid and ar.rid=r.rid and a.pid=p.pid and r.rid=s.rid and s.nurse_id=n_id 
    and curtime <s.shift_end_time and curtime>s.shift_start_time;

Begin
    select count(*) into ncount from nurse where nurse_id=n_id; --checking nurse id--
    if ncount = 0 then
        dbms_output.put_line('Invalid Nurse ID');
    else
        select count(*) into ncount from shifttable_nurse where nurse_id=n_id and curtime < shift_end_time  
        and curtime > shift_start_time; --checking nurse shift time--
        if ncount=0 then
            dbms_output.put_line('The nurse is not working at given time');
        else
            for r in C1 loop
                dbms_output.put_line('Room Details:'|| r.rid ||' ^^ '||r.room_location || ' ^^ ' || r.pname);
            end loop;
        end if;
    end if;
End;
/


----FEATURE 8 Discharge a patient----

create or replace 
    procedure discharge_patient(a_id in int, dischargedate in date, dischargenote in varchar)
As
    acount int;
    d_did int;
    p_pid int;
    msg message.message_body%type;
    tr_id int;
    trdr treatment.TDESCRIPTION%type;
    trdate date;
Cursor C1 is select atr.tid, t.T_INFO, atr.TREATDOB from admission a, treatment_list t, treatment atr 
        where a.aid=a_id and a.aid=atr.aid and atr.tid=t.tid;
Cursor C2 is select d.DRUG_NAME,d.DOSE_VALUE, d.DOSE_PERDAY,p.aid,p.PRESCRIPTION_DATE,p.NUMBER_OF_DAYS_DRUG,p.NUMBER_OF_REFILLS
       from drug d, prescription p where p.aid=a_id and p.DRUG_ID=d.DRUG_ID;

Begin
    select count(*) into acount from admission where aid=a_id; --checking admission id--
    if acount = 0 then
        dbms_output.put_line('Invalid Admission ID');
    else
        dbms_output.put_line('Success 1');
        select did, pid into d_did, p_pid from admission where aid=a_id;
        update admission set discharge_date=dischargedate, discharge_note=dischargenote, admit_status='discharged' where aid=a_id; --update admission table--
        msg:=('Patient discharged on' || dischargedate);--inserting message body in message table--
        insert into message values(dischargemessage.nextval,msg,CURRENT_TIMESTAMP,p_pid,d_did);
        dbms_output.put_line('List of Treatment as follows:');
        for r in C1 loop
                dbms_output.put_line(r.tid ||' ^^ ' || r.t_info || ' ^^ '|| r.treatdob);
        end loop; 
        dbms_output.put_line('List of Presciption as follows:');
        for j in C2 loop
                dbms_output.put_line(j.drug_name ||' ^^ ' || j.dose_value || ' ^^ '|| j.dose_perday 
                || ' ^^ '|| j.prescription_date  || ' ^^ '|| j.number_of_days_drug || ' ^^ '|| j.number_of_refills);
        end Loop;
    end if;  
End;
/


-----------------------------------------------------------
---group Feature
---Feature 9
create or replace procedure contact_tracing(patientname varchar, DOB date, in_date date) IS
    
    check_p int;   ---cheking  patient
    pat_hos int;   ---checking hospital
    r_id  room.rid%TYPE;  
    s_time room.start_time%TYPE;
    e_time room.end_time%TYPE;
    d_id   doctor.did%TYPE;
    d_name doctor.dname%TYPE;
    nursename varchar(20);
    shiftstarttime timestamp;   --shift start TIME
    shiftendtime timestamp;     ---shift end time 
    
    cursor c1 is select r.rid, r.start_time, r.end_time,d.did, d.dname from room r, admission a, patient p, doctor d
    where p.pid=a.pid and pname=patientname and pdob=DOB and in_date <= a.discharge_date and in_date >= a.current_admit_date
    and a.rid=r.rid and d.did=a.did;      ----cursor holds the values of room id, start time, end time, doctor id, doctor name
    
    cursor c2 is select distinct n.nurse_name, sn.shift_start_time, sn.shift_end_time from nurse n, shifttable_nurse sn, room r, admission a, admission_rooms ar, patient p
    where sn.nurse_id=n.nurse_id and p.pid=a.pid and a.rid=r.rid and r.rid=sn.rid and r.rid=ar.rid and p.pname=patientname and p.pdob=DOB and
    sn.shift_start_time<=ar.end_time and sn.shift_end_time<=ar.start_time;
    ----cursor holds the values of nurse name,shift start time, shift end time
       
    begin
    select count(*) into check_p from patient where pname=patientname and pdob=DOB; ---checking the patient with name and DOB
    
    select count(*) into pat_hos from patient p, admission a
    where p.pid=a.pid and pname=patientname and pdob=DOB and in_date < a.discharge_date and in_date > a.current_admit_date; 
	---checking the patient with name and DOB on that perticular day
    
    
    if (check_p=0)                   ---checking the patient with name and DOB
    then 
         dbms_output.put_line('Error: Patient does not Exists');
    
    else
    
          if(pat_hos=0)     	---checking the patient with name and DOB on that perticular day
          then 
              dbms_output.put_line('This patient is not in hospital on the given day');   
          
          else
          --If the patient is in hospital that day-> then doctor who oversees the patient's admission,  
                ---   with all rooms the patient was assigned to and start and end time of each assignment.
          open c1;
          loop
          fetch c1 into r_id , s_time , e_time , d_id, d_name;   ---print out room id, satrt time, end time, doctor id and name
          EXIT WHEN c1%NOTFOUND;
          DBMS_OUTPUT.PUT_LINE('Room ID    = ' || r_id);
          DBMS_OUTPUT.PUT_LINE('Start Time = ' || s_time);
          DBMS_OUTPUT.PUT_LINE('End Time   = ' || e_time);
          DBMS_OUTPUT.PUT_LINE('Doctor Id  = ' || d_id);
          DBMS_OUTPUT.PUT_LINE('Doctor name= ' || d_name);
          end loop;
          
           DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------');
           DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------');
           open c2;
           loop
           fetch c2 into nursename, shiftstarttime, shiftendtime;  
           EXIT WHEN c2%NOTFOUND;
           DBMS_OUTPUT.PUT_LINE('Nurse Name   = ' || nursename);     ---print out nurse name, shift in time and out time
          DBMS_OUTPUT.PUT_LINE('Start Time = ' || shiftstarttime);
          DBMS_OUTPUT.PUT_LINE('End Time   = ' || shiftendtime);
         end loop;
          
                
    end if;
    end if;
    end;
	/
	--------------------------------------------------------------
	--feature 10
	
	create or replace procedure room_stat(v_start_date date, v_end_date date, hos_id int) IS
    o_rate number;  ---occupancy rate
    hos_check int;   ---for hospital check
    check_room int; --checking rooms
    startDate date; --v_start_date
    endDate date;
    startTime timestamp;
    endTime timestamp;
    room_id int;
    loc varchar(30);  ---room location
    r_type varchar(20); ---room type
    x int; ---for rom id
    y int;    ----for summation of days -sum(day)
	
    cursor c1 is select distinct r.rid, r.room_location, r.room_type from admission a, room r, admission_rooms ar
    where a.aid=ar.aid and r.rid=ar.rid and a.hid=hos_id;   ---It holds the values of room id, room location, room type
    
 
    cursor c2 is select distinct r.rid, sum(extract(day from ar.end_time-ar.start_time)) days  from admission a, room r, admission_rooms ar 
    where a.aid=ar.aid and r.rid=ar.rid and a.hid=hos_id and ar.start_time>=startTime and ar.end_time<=endTime
    group by r.rid;    ---C2 holds the values of room id, and sum of extracted days from start time and end time
    
    
    begin
    o_rate:=0;
    startDate:=v_start_date;
    endDate:=v_end_date;
    select count(*) into hos_check from hospital where hid=hos_id;
    
    if (hos_check=0) then --check hospital is valid or not
    dbms_output.put_line('Incorrect Hospital Id');
    else
    
    for var_t in c1 loop
    startTime:=to_timestamp(startDate); --conversion of start to time
    endTime:=to_timestamp(endDate); ---end date to timesatmp
   
    select count(*) into check_room from admission_rooms ar, room r where r.rid=ar.rid and ar.start_time<=endTime and ar.end_time>=startTime;--checking the admissions in given period
    if (check_room>0) then
    
    --select sum(extract(day from ar.end_time-ar.start_time)) days into  y from admission a, room r, admission_rooms ar 
    --where a.aid=ar.aid and r.rid=ar.rid and a.hid=hos_id and ar.start_time>=startTime and ar.end_time<=endTime;
    --group by r.rid;                                                                                   ---room id, sum of days wrt room and given time
     open c2;
     loop
     fetch c2 into x,y;
     exit when c2%notfound;
     dbms_output.put_line(' Total days for each room that there is a patient assigned to room '||x||'  is   ' ||y); ---total number of days 
     o_rate:= (y/(endDate-startDate)*100);
     dbms_output.put_line(' Occupancy rate for room '||x||'  is  '||o_rate); ---calculation of occupancy rate
     dbms_output.put_line('Room ID '|| var_t.rid|| ' Room type '|| var_t.room_type||' location ' || var_t.room_location);
     dbms_output.put_line('');
     dbms_output.put_line('');
     dbms_output.put_line('');
     dbms_output.put_line('');
     end loop;
     close c2;
     end if;
	 end loop;
    
     end if;
    
    end;
	/
	
	------------------------------------------------------------------------------
	---Feature 11
	
	create or replace procedure shift_statistics(hos_id int, start_date date, end_date date)
as
hospital_cnt int;
    
    number_of_days int;  
    hour_1 float:=0; ---first shift hours
    average_hours float; ---avearge hrs per day
    nurse_name varchar(20);
    no_of_nurses int :=0;
    all_average float:=0;
    s_time timestamp;--start time
    e_time timestamp;--end time
    number_hrs int;
    hour_2 float:=0;  ---second shift hours
   
   
    cursor C2 is select n.nurse_name, sn.shift_start_time, sn.shift_end_time from nurse n, shifttable_nurse sn   
    where sn.nurse_id=n.nurse_id and hid=hos_id and trunc(sn.shift_start_time)<=end_date and 
    trunc(sn.shift_end_time)>=start_date order by n.nurse_name asc;   ----This cursor holds nurse names in perticular hospital with shift timimngs
    
    cursor C1 is select distinct n.nurse_name from nurse n, shifttable_nurse sn  
    where sn.nurse_id=n.nurse_id and hid=hos_id and trunc(sn.shift_start_time)<=end_date 
    and trunc(sn.shift_end_time)>=start_date order by n.nurse_name asc;  ----nurse names in perticular hospital
 
begin
    
    select count(*) into hospital_cnt from hospital where hid=hos_id;  ---checks the hosptal is present or not 
    
    if hospital_cnt=0 then
        dbms_output.put_line('Hospital Id is not present in DB');
    else 
         for r_var in C1 loop
            s_time:=to_timestamp(start_date) + interval '0 8:00:00.00' day to second;   ---conversion of date to timestamp with given condition
            e_time:=to_timestamp(end_date) + interval '0 8:00:00.00' day to second;     ---conversion of date to timestamp with given condition
            for r_var2 in C2 loop
                hour_1:=extract(day from(r_var2.shift_end_time - r_var2.shift_start_time))*24 +  
                extract(hour from (r_var2.shift_end_time - r_var2.shift_start_time)) + 
                extract(minute from(r_var2.shift_end_time - r_var2.shift_start_time))/60;  ---finding out hours of shift 1
                if r_var2.shift_end_time >e_time then
                    hour_2:=extract(day from(r_var2.shift_end_time - e_time))*24 +    ---finding out hours of shift 2
                    extract(hour from (r_var2.shift_end_time - e_time)) + 
                    extract(minute from(r_var2.shift_end_time - e_time))/60;
                end if;
               
                if(hour_1>24)
                then
                hour_1:=24;
                dbms_output.put_line('Working hours shift 1:'|| hour_1 || ' and shift 2:' || hour_2 ); ---8Am to 8Am shift
                ELSIF (hour_1>=12 and hour_1<24) then
                hour_1:=12;
                dbms_output.put_line('Working hours shift 1:'||hour_1 || ' and shift 2:' || hour_2 );  ---before 8Am-8pm or after 8pm shift
                else
                dbms_output.put_line('Working hours shift 1:'|| hour_1 || ' and shift 2:' || hour_2 ); ---8am to 8pm
                end if;
                number_hrs:=(hour_1-hour_2);   
                
                if number_hrs<>0 then
                    number_of_days:=end_date-start_date; --- no of days between the eduration 
                    average_hours:=(number_hrs/number_of_days); ---finding the average
                    no_of_nurses:=no_of_nurses + 1;  
                    all_average:=(all_average + average_hours)/(no_of_nurses); ---finding the everage total working hours
                end if;  
            end loop;
            dbms_output.put_line('Nurse name:'||r_var.nurse_name||' and Average working hours:-> '||average_hours);
        end loop;
        dbms_output.put_line('Total average hours-Nusrses:-> '||all_average); --- Collective average all teh nurses
    end if;
end;

/

---------------------------------------------------------------------------------------------
---feature 12th 

create or replace procedure Re_admission(inp_itr interval day to second)
IS
discharge_d date;
amission_date date;
r1 varchar(100); --admission reason
r2 varchar(100); -- readmission reason
hospital_name varchar(30);
p_nm varchar(30) ;---patinet name
hospital_id int;
admin_cnt int;
rate_readmin float;--readmission rate
t_re_patinets int;--total patients

Cursor c1 is select a2.discharge_date,a2.current_admit_date,a1.admit_reason,a2.admit_reason,p.pname from admission a1, admission a2, patient p where -- 1.
a1.pid = a2.pid and a1.aid<>a2.aid and a1.pid = p.pid and a2.pid = p.pid and 
a1.discharge_date < a2.current_admit_date and 
numtodsinterval(a2.current_admit_date - a1.discharge_date,'day')< = inp_itr; 
               ---cursor holds the values of discharge date, admit date, admission reasons, patient names
Cursor c2 is select hid, hname from hospital; -- All the hospital names 
Begin
open c1;
Loop
fetch c1 into discharge_d, amission_date, r1, r2,p_nm; 
exit when c1%notfound;
    dbms_output.put_line('Patient Name: '|| p_nm || ' '||' Admission Date: ' || amission_date || ' Discharge date: ' || discharge_d || ' Reason 1: ' || r1 || ' Reason 2: ' || r2 );
end loop;                                         ----printing out patinet anme, discharge and admission date with admission reasons
close c1;
open c2;
loop
fetch c2 into hospital_id, hospital_name;
exit when c2%notfound;
   
    select count(*) into admin_cnt from admission a1, admission a2 where a1.pid = a2.pid and a1.aid<>a2.aid
    and a1.discharge_date< a2.current_admit_date and a1.hid = hospital_id and 
    numtodsinterval(a2.current_admit_date - a1.discharge_date,'day') <= inp_itr ;    ---gets th ereadmission count 
    select count(distinct(pid)) into t_re_patinets from admission where hid = hospital_id;
   if(t_re_patinets<>0) then
    rate_readmin := (admin_cnt/t_re_patinets)*100;  --readmission rate of a hospital 
    dbms_output.put_line('Hospital Name: ' || hospital_name || ' readmission rate: ' || rate_readmin); 
    else 
    dbms_output.put_line('Hospital Name: ' || hospital_name || ' readmission rate: ' || 0);
    end if;
    
end loop;
close c2;
end;
/




	