create or replace procedure SD_sp_tbl_IPL
as
begin
 -- table scoresheet
begin
Execute immediate 'Drop table SD_tbl_IPL';
Exception when others then NULl;
end;
execute immediate 'create table SD_tbl_IPL(
team_id number constraint pk_tbl_IPL primary key,
team_short varchar2(10),
team_name varchar2(50)
)';

-- Ipl matchresult
begin
 Execute immediate 'Drop table SD_tbl_IPL_Matchresult';
 Exception when others then NULl;
 end;
 execute immediate 'create table SD_tbl_IPL_Matchresult(
 Team1 number,
 Runs_scored1 number,
 Overs1 float,
 Wickets1 number,
 Team2 number,
 Runs_scored2 number,
 Overs2 float,
 Wickets2 number,
 Remarks varchar2(100),
 Home_id number,
 Away_id number,
 M_type varchar(2)
 )';
 end SD_sp_tbl_IPL;


-- execute create procedure

exec SD_sp_tbl_IPL;


--insert and update package

create or replace package SD_pakg_IPl_insert
as
procedure SD_sp_insert_IPL(team_id number, team_name varchar2, team_short varchar2);
procedure SD_sp_matchresult(Team1_Id number, Runs1 number, wickets1 number, overs1 float, Team2_Id number, Runs2 number, wickets2 number ,overs2 float, dls number, match_type varchar2, home_id number);
function SD_fn_runrate(Team_id number) return float;
function SD_fn_played(id1 number) return number;
function SD_fn_leaguetable(id1 number,Colm varchar2) return number;
function SD_fn_winner(h_id number, a_id number) return varchar2;
function SD_fn_progtable(id1 number , Colm varchar2) return varchar2;
end;
/

create or replace package body SD_pakg_IPl_insert
as
 --procedure for insert into table
procedure SD_sp_insert_IPL(team_id number, team_name varchar2, team_short varchar2)
as
begin
insert into SD_tbl_IPL values(team_id, team_short, team_name);
commit;
end SD_sp_insert_IPL;

-- proc for match results
procedure SD_sp_matchresult(Team1_Id number, Runs1 number, wickets1 number, overs1 float, Team2_Id number, Runs2 number, wickets2 number ,overs2 float, dls number, match_type varchar2, home_id number)
as
remarks varchar2(50);
Team1_name VARCHAR2(50);
Team2_name VARCHAR2(50);
away_id number;
begin
    if home_id=Team1_id
    then away_id:=Team2_id;
    elsif home_id=0
    then away_id:=0;
    else
    away_id:=Team1_id;
    end if;
    select team_name into Team1_name from SD_tbl_IPL where team_Id=Team1_Id;
    select team_name into Team2_name from SD_tbl_IPL where team_Id=Team2_Id;
    if Runs1>Runs2 then remarks:= Team1_name||' won by '''||(Runs1-Runs2)||''' runs';
    elsif Runs1<Runs2 then remarks:= Team2_name||' won by '''||(10-wickets2)||''' wickets';
    end if;
    IF dls=1 THEN
    remarks:=concat(remarks,'(DLS METHOD)');
    END IF;
  insert into SD_tbl_IPL_Matchresult values(Team1_id, Runs1, overs1, wickets1, Team2_id, Runs2, overs2, wickets2, remarks, home_id, away_id, match_type);
 commit;
end SD_sp_matchresult;

-- function for played
function SD_fn_played(id1 number)
return number
as
total_p number;
name varchar2(50);
begin
select count(*) into total_p from SD_tbl_IPL_Matchresult where M_type='L' and (Team1=id1 or Team2=id1);
return total_p;
end;


-- function for  league and progression table
function SD_fn_leaguetable(id1 number , Colm varchar2)
return number
as
name varchar2(50);
win number;
lose number;
tie number;
nr number;
pts number;
cnum number;
type progress IS VARRAY(15) OF INTEGER;
games progress;
i number;

begin
i:=0;
games:= progress(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
win:=0;
lose:=0;
tie:=0;
nr:=0;
pts:=0;
FOR f  IN (select * from SD_tbl_IPL_Matchresult where M_type='L' and (Team1=id1 or Team2=id1))
loop
if f.Team1=id1 then
    i:=i+1;
    if f.Runs_scored1>f.Runs_scored2
    then win:= win+1;
    games(i+1):= games(i)+2;
    elsif f.Runs_scored1<f.Runs_scored2
    then lose:=lose+1;
    games(i+1):= games(i)+0;
    elsif f.Runs_scored1=f.Runs_scored2
    then tie:= tie+1;
    games(i+1):= games(i)+1;
    else
    nr :=nr+1;
    games(i+1):= games(i)+0;
    end if;

elsif f.Team2=id1 then
    i:=i+1;
    if f.Runs_scored2>f.Runs_scored1
    then win:= win+1;
    games(i+1):= games(i)+2;
    elsif f.Runs_scored2<f.Runs_scored1
    then lose:=lose+1;
    games(i+1):= games(i)+0;
    elsif f.Runs_scored1=f.Runs_scored2
    then tie:= tie+1;
    games(i+1):= games(i)+1;
    else
    nr :=nr+1;
    games(i+1):= games(i)+0;
    end if;
end if;
end loop;
pts:=win*2+tie*1;
if Colm='W' then
return win;
elsif Colm='L' then
return lose;
elsif Colm='T' then
return tie;
elsif Colm='NR' then
return nr;
elsif  Colm='PTS' then
return pts;
else
cnum:=to_number(Colm,'99');
return games(cnum+1);
end if;
end SD_fn_leaguetable;


--function for league progression Q1,E,Q2,F
function SD_fn_progtable(id1 number , Colm varchar2)
return varchar2
as
Q1 varchar2(1);
Q2 varchar2(1);
Fi varchar2(1);
name varchar2(50);
begin
FOR f IN(select * from SD_tbl_IPL_Matchresult where M_type!='L' and (Team1=id1 or Team2=id1))
Loop
if f.M_type='Q1' or f.M_type='E' then
    if f.Team1=id1 then
        if f.Runs_scored1>f.Runs_scored2
        then Q1:='W';
        else
        Q1:='L';
        end if;
    elsif f.Team2=id1 then
        if f.Runs_scored1<f.Runs_scored2
        then Q1:='W';
        else
        Q1:='L';
        end if;
    end if;

elsif f.M_type='Q2' then
     if f.Team1=id1 then
        if f.Runs_scored1>f.Runs_scored2
        then Q2:='W';
        else
        Q2:='L';
        end if;
    elsif f.Team2=id1 then
        if f.Runs_scored1<f.Runs_scored2
        then Q2:='W';
        else
        Q2:='L';
        end if;
    end if;
else
     if f.Team1=id1 then
        if f.Runs_scored1>f.Runs_scored2
        then Fi:='W';
        else
        Fi:='L';
        end if;
    ELSIF f.Team2=id1 then
        if f.Runs_scored1<f.Runs_scored2
        then Fi:='W';
        else
        Fi:='L';
        end if;
    end if;
end if;
end loop;
if Colm='Q1' then
return Q1;
elsif Colm='Q2' then
return Q2;
else
return Fi;
end if;
end SD_fn_progtable;



-- function for runrate
function SD_fn_runrate(Team_id number)
 return float
 as
 Tid number;
 runrate number;
 team_run number;
 team_runagainst number;
 team_balls number;
 teamagainst_balls number; 
 netrunrate float;
 begin
  team_run:=0;
  team_runagainst:=0;
  team_balls:=0;
  teamagainst_balls:=0;
  teamagainst_balls:=0;
  Tid:= Team_id;
  select sum(rs) into team_run from(
   select sum(Runs_scored1)as rs  from SD_tbl_IPL_Matchresult where Team1=Tid and M_type='L' 
   union all
   select sum(Runs_scored2)as rs from SD_tbl_IPL_Matchresult where Team2=Tid and M_type='L');
   
  select sum(rs) into team_runagainst from(
   select sum(Runs_scored1)as rs from SD_tbl_IPL_Matchresult where Team2=Tid and M_type='L' 
   union all
   select sum(Runs_scored2)as rs from SD_tbl_IPL_Matchresult where Team1=Tid and M_type='L');

  select sum(balls) into team_balls from(
   select sum(trunc(Overs1/1))*6 + Sum(Ltrim(Mod(Overs1,1),'.')) as balls from SD_tbl_IPL_Matchresult where Team1=Tid and Wickets1<10 and M_type='L'
   union all
   select sum(trunc(Overs2/1))*6 + Sum(Ltrim(Mod(Overs2,1),'.')) as balls from SD_tbl_IPL_Matchresult where Team2=Tid and Wickets2<10 and M_type='L'
   union all
   select sum(120) as balls from SD_tbl_IPL_Matchresult where Team1=Tid and Wickets1=10 and M_type='L'
   union all
   select sum(120) as balls from SD_tbl_IPL_Matchresult where Team2=Tid and Wickets2=10 and M_type='L');
  
  select sum(balls) into teamagainst_balls from(
   select sum(trunc(Overs1/1))*6 + Sum(Ltrim(Mod(Overs1,1),'.')) as balls from SD_tbl_IPL_Matchresult where Team2=Tid and Wickets1<10 and M_type='L'
   union all
   select sum(trunc(Overs2/1))*6 + Sum(Ltrim(Mod(Overs2,1),'.')) as balls from SD_tbl_IPL_Matchresult where Team1=Tid and Wickets2<10 and M_type='L'
   union all
   select sum(120) as balls from SD_tbl_IPL_Matchresult where Team2=Tid and Wickets1=10 and M_type='L'
   union all
   select sum(120) as balls from SD_tbl_IPL_Matchresult where Team1=Tid and Wickets2=10 and M_type='L');

  netrunrate:=round(((team_run/team_balls)-(team_runagainst/teamagainst_balls))*6,3);
  return netrunrate;
 end SD_fn_runrate;
 
 -- function to fin winner for match summary
 function SD_fn_winner(h_id number, a_id number)
 return varchar2
 as
 s_name varchar2(5);
 begin
 For f in (select * from SD_tbl_IPL_Matchresult  join  where Home_id=h_id and Away_id=a_id and M_type='L')
 loop
 if (f.Runs_scored1 > f.Runs_scored2) then
 select team_short into s_name from SD_tbl_IPL where team_id=f.Team1;
 else
 select team_short into s_name from SD_tbl_IPL where team_id=f.Team2;
 end if;
 end loop;
 return s_name;
 end SD_fn_winner;
end SD_pakg_IPl_insert;
/

-- execute for insert in table

exec SD_pakg_IPL_insert.SD_sp_insert_IPL(1 ,'Chennai Super Kings', 'CSK');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(2 ,'Delhi Daredevils', 'DD');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(3 ,'Kings XI Punjab', 'KXIP');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(4 ,'Kolkata Knight Riders', 'KKR');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(5 ,'Mumbai Indians', 'MI');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(6 ,'Rajasthan Royals', 'RR');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(7 ,'Royal Challengers Banglore', 'RCB');
exec SD_pakg_IPL_insert.SD_sp_insert_IPL(8 ,'Sunrisers Hyderbad', 'SRH');

-- execute for insert in table
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,165,4,20,1,169,9,19.5,0,'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,166,7,20,3,167,4,18.5,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,176,7,20,4,177,6,18.5,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,125,9,20,8,127,1,15.5,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,202,6,20,1,205,5,19.5,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,70,5,6.0,2,60,4,6,1, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,147,8,20,8,151,9,20,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,155,10,19.2,7,159,6,19.3,0, 'L', 7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,194,7,20,2,195,3,20,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,138,8,20,8,139,5,19,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,217,4,20,7,198,6,20,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,197,7,20,1,193,5,20,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,200,9,20,2,129,10,14.2,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,213,6,20,7,167,8,20,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,160,8,20,4,163,3,18.5,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,193,3,20,8,178,4,20,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,204,5,20,6,140,10,18.3,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,124,7,13,3,126,1,11.1,1, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,174,5,20,7,176,4,18,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,182,3,20,8,178,6,20,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,167,7,20,6,168,7,19.4,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,143,8,20,2,139,8,20,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,118,10,18.4,5,87,10,18.5,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,205,8,20,1,207,5,19.4,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,132,6,20,3,119,10,19.2,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,219,4,20,4,164,9,20,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,169,5,20,5,170,2,19.4,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,151,7,20,6,140,6,20,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,175,4,20,4,176,4,19.1,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,211,4,20,2,198,5,20,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,167,7,20,5,153,7,20,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,150,6,12.0,6,146,5,12,1, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,177,5,20,4,180,4,17.4,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,174,6,20,5,176,4,19,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,127,9,20,1,128,4,18,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,163,5,20,8,164,3,19.5,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,181,4,20,4,168,6,20,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,152,9,20,3,155,4,18.4,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,146,10,20,7,141,6,20,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,158,8,20,3,143,7,20,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,210,6,20,4,108,10,18.1,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,187,5,20,8,191,1,18.5,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(1,176,4,20,6,177,6,19.5,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,245,6,20,3,214,8,20,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,181,4,20,7,187,5,19,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,179,4,20,1,180,2,19,0, 'L',1);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,168,6,20,6,171,3,18,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,88,10,15.1,7,92,0,8.1,0, 'L',3);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,142,10,19,4,145,4,18,0, 'L',4);
exec SD_pakg_IPl_insert.SD_sp_matchresult(5,186,8,20,3,183,5,20,0, 'L',5);
exec SD_pakg_IPl_insert.SD_sp_matchresult(7,218,6,20,8,204,3,20,0, 'L',7);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,162,5,20,1,128,6,20,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(6,164,5,20,7,134,10,19.2,0, 'L',6);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,172,9,20,4,173,5,19.2,0, 'L',8);
exec SD_pakg_IPl_insert.SD_sp_matchresult(2,174,4,20,5,163,10,19.3,0, 'L',2);
exec SD_pakg_IPl_insert.SD_sp_matchresult(3,153,10,19.4,1,159,5,19.1,0, 'L',1);

--- exec for eliminator, qualifier and final
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,139,7,20,1,140,8,19.1,0, 'Q1',0);
exec SD_pakg_IPl_insert.SD_sp_matchresult(4,169,7,20,6,144,4,20,0, 'E',0);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,174,7,20,4,160,9,20,0, 'Q2',0);
exec SD_pakg_IPl_insert.SD_sp_matchresult(8,178,6,20,1,181,2,18.3,0, 'F',0);



-- select statement
select * from SD_tbl_IPL;
select * from SD_tbl_IPL_Matchresult;

--truncate table
truncate table SD_tbl_IPL;
truncate table SD_tbl_IPL_Matchresult;


--create or replace view SD_league_progression as
create or replace view SD_league_progression as
select team_name as League
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'1') as "1"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'2') as "2"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'3') as "3"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'4') as "4"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'5') as "5"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'6') as "6"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'7') as "7"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'8') as "8"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'9') as "9"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'10') as "10"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'11') as "11"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'12') as "12"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'13') as "13"
      ,Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'14') as "14"
      ,Sd_pakg_IPL_insert.SD_fn_progtable(team_id,'Q1') as "Q1E"
      ,Sd_pakg_IPL_insert.SD_fn_progtable(team_id,'Q2') as Q2
      ,Sd_pakg_IPL_insert.SD_fn_progtable(team_id,'F') as "F"
      from SD_tbl_IPL;

 SELECT * FROM  SD_league_progression;

create or replace view SD_Match_Table as
 select team_name as Name
      , SD_pakg_IPl_insert.SD_fn_played(team_id)as Pld
      , Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id, 'W') as W
      , Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id, 'L')as L
      , Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id, 'T')as T
      , Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'NR')as NR
      , Sd_pakg_IPL_insert.SD_fn_leaguetable(team_id,'PTS')as PTS
      , Sd_pakg_IPL_insert.SD_fn_runrate(team_id) as NRR
      from SD_tbl_IPL
      order by PTS desc, NRR DESC;

SELECT * from SD_Match_Table;

create or replace view SD_match_summary as
WITH x AS (
SELECT * FROM(
select h.Home_team, a.Away_team , Sd_pakg_IPL_insert.SD_fn_winner(h.Home_id, a.Away_id) as winner  from (SELECT  row_number() over(order by 1) as rw,a.team_name as Home_Team,b.Home_id from SD_tbl_IPL_Matchresult b join SD_tbl_IPL a on a.team_id=b.Home_id) h join
            (SELECT row_number() over(order by 1) as rw, a.team_short as Away_Team,b.Away_id from SD_tbl_IPL_Matchresult b join SD_tbl_IPL a on a.team_id=b.Away_id) a on a.rw=h.rw
)
pivot( Max(winner) FOR Away_team IN ('CSK' AS CSK,'DD' AS DD,'KXIP' AS KXIP,'KKR' AS KKR,'MI' AS MI,'RR' AS RR,'RCB' AS RCB,'SRH' as SRH, 'Null' AS "NULL", 'Null' AS "NULL1", 'Null' AS "NULL2", 'Null' AS "NULL3", 'Null' AS "NULL4", 'Null' AS "NULL5", 'Null' AS "NULL6", 'Null' AS "NULL7", 'Null' AS "NULL8")))
SELECT * FROM x ORDER BY Home_Team;


select * from SD_match_summary;


--- create views after union
create or replace view SD_tables_view as
select rownum as rw,a.* from(
select '' as " ",''as "  ",''as "   ",''as "    ",'Group' as "Group",'Matches' as Matches,''as "     ",''as "      ",''as "       ",''as "        ",''as "         ",''as "          ",''as "           ",''as "            ",''as "             ",''as PlayOffs,''as "              ",''as "               " from dual where 1=2
union all
select 'League progression','1','2','3','4','5','6','7','8','9','10','11','12','13','14','Q1\E','Q2','F' from dual
union all
SELECT League,
       To_Char("1") as "1",
       To_Char("2") as "2",
       To_Char("3") as "3",
       To_Char("4") as "4",
       To_Char("5") as "5",
       To_Char("6") as "6",
       To_Char("7") as "7",
       To_Char("8") as "8",
       To_Char("9") as "9",
       To_Char("10") as "10",
       To_Char("11") as "11",
       To_Char("12") as "12",
       To_Char("13") as "13",
       To_Char("14") as "14",
       "Q1E",
        Q2,
       "F"
 from SD_league_progression
UNION ALL
select '','','','','','','','','','','','','','','','','','' from dual
Union ALL
SELECT 'Match summary', 'CSK', 'DD', 'KXIP', 'KKR', 'MI','RR', 'RCB', 'SRH','','','','','','','','','' FROM dual
UNION ALL
SELECT * FROM SD_match_summary
UNION ALL
select '','','','','','','','','','','','','','','','','','' from dual
Union ALL
select '','','','','','','','','','','','','','','','','','' from dual
Union ALL
select 'League Table','', '', '', '', '', '','','','','','','','','','','','' FROM dual
Union all
SELECT 'Team', 'PLD', 'W', 'L', 'T', 'NR', 'PTS','NRR','','','','','','','','','','' FROM dual
UNION ALL
SELECT Name, To_Char(PLD), To_Char(W), To_Char(L), To_Char(T), To_Char(NR), To_Char(PTS),To_Char(NRR),'','','','','','','','','','' FROM SD_Match_Table
) a;

select * from SD_tables_view;

-- view of vs table
create or replace view SD_vsview as
select rownum as rc,Team1,v,Team2,Remarks from(
SELECT rownum as rn,Team1,'v'as v, Team2, Remarks FROM 
((SELECT ROWNUM AS rw,b.team_name AS Team1 FROM SD_tbl_IPL_Matchresult a JOIN SD_tbl_IPL b ON a.Team1=b.team_id) x 
JOIN 
(SELECT ROWNUM AS rw, b.team_name AS Team2, Remarks As Remarks FROM SD_tbl_IPL_Matchresult a JOIN SD_tbl_IPL b ON a.Team2=b.team_id) y ON x.rw=y.rw) 
union 
select rownum as rn, Runs_scored1||'/'||Wickets1||'('||Overs1||' overs)' as Score1,'',Runs_scored2||'/'||Wickets2||'('||Overs2||' overs)' as Score2,'' from SD_tbl_IPL_Matchresult
union 
select rownum as rn,'','','',''from SD_tbl_IPL_Matchresult
)
order by rn, Team1 desc;

select * from SD_vsview;

--view of match result
create or replace view SD_matchresult 
AS
select rownum as rw,a.* from(
select '' as " ",'' as "  ",'' as "MatchResultsLeague",'' as "   " from dual where 1=2
union all
select Team1,v,Team2,Remarks from SD_vsview where rc!=3)a;

select * from SD_matchresult;

--view of match result second part
create or replace view SD_matchresult_second as
select rownum as rw,a.* from(
select '' as " ",'' as "  " ,'' as "MatchResultsLeague",'' as "   " from dual where 1=2
union all
select a." ",a."  ",a. "MatchResultsLeague",a."   " from SD_matchresult a where rw>=85)a;

--view for the center-top
create or replace view SD_centertopview as
select a." ",a."  ",a."   "
,b." " as "    "
,b."  " as "     "
,b."   " as "      "
,b."    " as "       "
,b."Group" as "Group"
,b.Matches as Matches
,b."     " as "        "
,b."      " as "         "
,b."       " as "          "
,b."        " as "           "
,b."         " as "            "
,b."          " as "             "  
,b."           " as "              "
,b."            " as "               "
,b."             " as "                "
,b.PlayOffs as  PlayOffs
,b."              " as "                 "
,b."               " as "                  "

,c." " as "                   "
from(
(select rownum as rw, '' as " ",'' as "  ",'' as "   " from dual)a
right join
(select * from SD_tables_view)b
on a.rw=b.rw
left join 
(select rownum as rw, '' as " " from dual)c
on b.rw=c.rw
);

select * from SD_centertopview;


-- view for the centerview
create or replace view SD_centerview
AS
SELECT * from(
select rownum as rw,z.* from (
select * from SD_centertopview
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','P','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','Qualifier-1','','','','','','','','','','','','','','','','','','' from dual
union all
select '','L','',team_name,to_char(Runs_scored1||'/'||Wickets1||'('||Overs1||')'),'','','','','','','','','','','','','','','','',''  from(select a.team_name,b.Runs_scored1,b.Wickets1,b.Overs1 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team1=a.team_id where M_type='Q1')
union all
select '','','',team_name,to_char(Runs_scored2||'/'||Wickets2||'('||Overs2||')'),'','','','','','','','','','','','','','','','','' from(select a.team_name,b.Runs_scored2,b.Wickets2,b.Overs2 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team2=a.team_id where M_type='Q1') 
union all
select '','A','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','Q2','','','','','','','','','','','','','' from dual
union all
select '','Y','','','','','','',team_short,to_char(Runs_scored1||'/'||Wickets1||'('||Overs1||')'),'','','','','','','','','','','',''  from(select a.team_short,b.Runs_scored1,b.Wickets1,b.Overs1 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team1=a.team_id where M_type='Q2')
union all
select '','','','','','','','',team_short,to_char(Runs_scored2||'/'||Wickets2||'('||Overs2||')'),'','','','','','','','','','','',''  from(select a.team_short,b.Runs_scored2,b.Wickets2,b.Overs2 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team2=a.team_id where M_type='Q2')
union all
select '','O','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','F','','Eliminator','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','',team_name,to_char(Runs_scored1||'/'||Wickets1||'('||Overs1||')'),'','','','','','','','','','','','','','','','',''  from(select a.team_name,b.Runs_scored1,b.Wickets1,b.Overs1 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team1=a.team_id where M_type='E')
union all
select '','F','',team_name,to_char(Runs_scored2||'/'||Wickets2||'('||Overs2||')'),'','','','','','','','','','','','','','','','','' from(select a.team_name,b.Runs_scored2,b.Wickets2,b.Overs2 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team2=a.team_id where M_type='E') 
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','S','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','F','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','I','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','N','',team_name,to_char(Runs_scored2||'/'||Wickets2||'('||Overs2||')'),'','','','','','','','','','','','','','','','',''  from(select a.team_name,b.Runs_scored2,b.Wickets2,b.Overs2 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team2=a.team_id where M_type='F')
union all
select '','A','',team_name,to_char(Runs_scored1||'/'||Wickets1||'('||Overs1||')'),'','','','','','','','','','','','','','','','','' from(select a.team_name,b.Runs_scored1,b.Wickets1,b.Overs1 from SD_tbl_IPL a join SD_tbl_IPL_Matchresult b on b.Team1=a.team_id where M_type='F') 
union all
select '','L','','','','','','','','','','','','','','','','','','','','' from dual
union all
select '','','','','','','','','','','','','','','','','','','','','','' from dual
)z);

select * from SD_centerview;
--view entire project
create or replace view SD_IPL_project as 
select x." " as "                    ",
       x."  " as "                     ",
       x."MatchResultsLeague",
       x."   " as "                      ",
       z." "
      ,z."  "
      ,z."   "
      ,z."    "
      ,z."     "
      ,z."      "
      ,z."       "
      ,z."Group"
      ,z.Matches
      ,z."        "
      ,z."         "
      ,z."          "
      ,z."           "
      ,z."            "
      ,z."             "  
      ,z."              "
      ,z."               "
      ,z."                "
      ,z.PlayOffs
      ,z."                 "
      ,z."                  "
      ,z."                   "
      ,y." " as "                       ",
       y."  " as "                        ",
       y."MatchResultsLeague" as " MatchResultsLeague",
       y."   " as "                         "
from(
(select * from SD_matchresult where rw<=85)x
left join
(select * from SD_centerview)z
on x.rw=z.rw
join
(select * from SD_matchresult_second)y
on x.rw=y.rw
);


-- ALL tables using single select statement
SELECT * FROM SD_IPL_project;
