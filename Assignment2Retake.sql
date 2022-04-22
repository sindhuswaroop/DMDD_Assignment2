set serveroutput on;

--drop table NYC_Parking_lot;

--Parking Space Table creation
declare 
v_cnt number;
begin
    select count(*) into v_cnt from user_tables where table_name = upper('NYC_Parking_lot');
    if v_cnt = 0 then
        execute immediate('
            create table NYC_Parking_lot (
            parking_space_id number primary key,
            parking_space_status varchar(20) default ''A'',
            constraint check_status check (parking_space_status=''A'' OR parking_space_status=''O''),
            parked_car_color varchar(50),
            parked_car_reg_number varchar(50) constraint reg_unique unique,
            checkin_dt date,
            checkout_dt date)');
        dbms_output.put_line('NYC_Parking_lot table created');
    else
        execute immediate('Delete from NYC_Parking_lot');
        commit;
        dbms_output.put_line('NYC_Parking_lot table already exists; deleted existing data and inserting again');
    end if;
end;
/

begin
    for j in 1..15
    loop
        insert into nyc_parking_lot (parking_space_id) values (j);
    end loop;
    commit;
end;
/

--Get empty parking spaces procedure
create or replace procedure Get_Empty_Parking_Space_Number is

begin
    dbms_output.put_line('Available parking spaces are: ');
    for i in (select parking_space_id, parking_space_status from nyc_parking_lot where parking_space_status = 'A')
loop
    dbms_output.put_line(i.parking_space_id);
end loop;
    
end;
/

exec Get_Empty_Parking_Space_Number;

-- Check In Procedure
create or replace procedure Checkin_Parking_Space (car_color varchar, car_reg_number varchar, checkin_date varchar, parking_space_num in out number) is

v_status varchar(50);
v_parking_space_num number;
v_checkin_date date;

e_notavailable exception;
e_invalidparkingspace exception;
e_carregnumberReqd exception;

begin
    if parking_space_num not in (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15) then
        raise e_invalidparkingspace;
    end if;
    
    if length(car_reg_number) is null then
        raise e_carregnumberReqd;
    end if;
    
    if length(checkin_date) is null then
       v_checkin_date := sysdate ;
    else
        v_checkin_date := to_date(checkin_date, 'DD-MON-YYYY');
    end if;
    
    select parking_space_status into v_status from nyc_parking_lot where parking_space_id = parking_space_num;
    if v_status != 'A' then
        raise e_notavailable;
    end if;
    
    update nyc_parking_lot set parking_space_status = 'O', parked_car_color=car_color, parked_car_reg_number=upper(car_reg_number), 
                            checkin_dt=v_checkin_date, checkout_dt = null where parking_space_id=parking_space_num;
    dbms_output.put_line('You have been checked into parking space number ' || parking_space_num || ' successfully.');
    commit;
    
    exception 
        when e_invalidparkingspace then dbms_output.put_line('Please enter a valid parking space number between 1 and 15.');
        when e_carregnumberReqd then dbms_output.put_line('Car registration number is a required field.');
        when e_notavailable then dbms_output.put_line('Sorry, parking space number ' || parking_space_num || ' is not available.');
        when dup_val_on_index then dbms_output.put_line('Sorry, car registration number ' || car_reg_number || ' has already been checked in.');
        when no_data_found then
            --When parking space input is null, assigns the first available parking space in the table
            select parking_space_id into v_parking_space_num from (select parking_space_id from nyc_parking_lot where parking_space_status = 'A') where rownum=1;
            update nyc_parking_lot set parking_space_status = 'O', parked_car_color=car_color, parked_car_reg_number=upper(car_reg_number), 
                            checkin_dt=v_checkin_date where parking_space_id=v_parking_space_num;
            dbms_output.put_line('Here is your parking space number: ' || v_parking_space_num);
        when others then dbms_output.put_line('CONTACT ADMIN'); 
        
end;
/

--select * from nyc_parking_lot;

--A
declare
id number;
begin
    id := 14;
    checkin_parking_space('RED', 'UBX987', '1-JAN-2022', id);
end;
/
--B
declare
id number;
begin
    id := '';
    checkin_parking_space('WHITE', 'ZZX954', '1-JAN-2022', id);
end;
/
--C
declare
id number;
begin
    id := '';
    checkin_parking_space('YELLOW', 'UEX982', '1-JAN-2022', id);
end;
/
--D
declare
id number;
begin
    id := '';
    checkin_parking_space('BLUE', 'AAX983', '2-JAN-2022', id);
end;
/
--E
declare
id number;
begin
    id := '';
    checkin_parking_space('RED', 'BBX987', '3-JAN-2022', id);
end;
/
--F
declare
id number;
begin
    id := 14;
    checkin_parking_space('RED', 'CCX585', '4-JAN-2022', id);
end;
/
--G
declare
id number;
begin
    id := 13;
    checkin_parking_space('WHITE', 'CCX585', '4-JAN-2022', id);
end;
/
--H
declare
id number;
begin
    id := 15;
    checkin_parking_space('YELLOW', 'CCX585', '4-JAN-2022', id);
end;
/
--I
declare
id number;
begin
    id := 11;
    checkin_parking_space('BLUE', 'CCX585', '4-JAN-2022', id);
end;
/
--J
declare
id number;
begin
    id := 12;
    checkin_parking_space('WHITE', 'CCX585', '4-JAN-2022', id);
end;
/
--Invalid parking space number 
declare
id number;
begin
    id := 16;
    checkin_parking_space('RED', 'UBX987', '1-JAN-2022', id);
end;
/
exec Get_Empty_Parking_Space_Number;

--Check Out procedure
create or replace procedure Check_Out_Parking_Lot (car_reg_number varchar, checkout_date varchar) is

v_checkout_date date;
v_carreg number;
v_carcheckedout number;

e_carregnumberReqd exception;
e_invalidcarreg exception;
e_carcheckedout exception;

begin
    
    select count(*) into v_carreg from nyc_parking_lot where parked_car_reg_number = upper(car_reg_number);
    
    if length(car_reg_number) is null then
        raise e_carregnumberReqd;
    end if;
    
    if v_carreg = 0 then
        raise e_invalidcarreg;
    end if;
    
    select count(*) into v_carcheckedout from nyc_parking_lot where parked_car_reg_number = upper(car_reg_number) and parking_space_status = 'A';
    
    if v_carcheckedout != 0 then
        raise e_carcheckedout;
    end if;
    
    if length(checkout_date) is null then
       v_checkout_date := sysdate ;
    else
        v_checkout_date := to_date(checkout_date, 'DD-MON-YYYY');
    end if;
    
    update nyc_parking_lot set parking_space_status = 'A', checkout_dt=v_checkout_date where parked_car_reg_number=upper(car_reg_number);
    dbms_output.put_line('You have been checked out of parking space successfully.');
    commit;
    
    exception 
        when e_carregnumberReqd then dbms_output.put_line('Car registration number is a required field.');
        when e_invalidcarreg then dbms_output.put_line('Invalid car registration number.'); 
        when e_carcheckedout then dbms_output.put_line('Car has already been checked out.'); 
        when others then dbms_output.put_line('CONTACT ADMIN'); 
        rollback;
end;
/
--select * from nyc_parking_lot;

--Checking out white cars
exec Check_Out_Parking_Lot('ZZX954', sysdate);
exec Check_Out_Parking_Lot('CCX585', '5-JAN-2022');

--Checking out car again after its already checked out
exec Check_Out_Parking_Lot('CCX585', '5-JAN-2022');

--Car registration number field null
exec Check_Out_Parking_Lot('', sysdate);

--Invalid car registration number
exec Check_Out_Parking_Lot('CCX985', '5-JAN-2022');

--Lower case car registration number and checked out on sysdate
exec Check_Out_Parking_Lot('uex982', sysdate);

exec Get_Empty_Parking_Space_Number;
