 select * from ipl_bidder_details;
 select * from ipl_bidder_points;
 select * from ipl_bidding_details;
 select * from ipl_match;
 select * from ipl_match_schedule;
 select * from ipl_player;
 select * from ipl_stadium;
 select * from ipl_team;
 select * from ipl_team_players;
 select * from ipl_team_standings;
 select * from ipl_tournament;
 select * from ipl_user;

/*1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.*/
#creating view for percentage calculation:
 create view q1 as
 select ibgd.bidder_id, NO_OF_BIDS, BID_STATUS, sum(if (BID_STATUS='won' , 1, 0))win_status 
 from ipl_bidder_points ibp 
 join ipl_bidding_details ibgd
 on ibp.BIDDER_ID=ibgd.BIDDER_ID
 group by BIDDER_ID;
 #percentage calculation:
select bidder_id , (win_status*100/ no_of_bids)percentage from q1 
group by bidder_id order by percentage desc;
 
 # using CTE
 use ipl;
 with bid (id,no_of_bids, bid_status,win_status) as 
 (
 select ibgd.bidder_id, NO_OF_BIDS, BID_STATUS, sum(if (BID_STATUS='won' , 1, 0))win_status 
 from ipl_bidder_points ibp 
 join ipl_bidding_details ibgd
 on ibp.BIDDER_ID=ibgd.BIDDER_ID
 group by BIDDER_ID
 )
select id,no_of_bids, bid_status,(win_status*100/no_of_bids)percentage from bid;


/*2.	Which teams have got the highest and the lowest no. of bids?*/
 #highest no of bids:
 select it.TEAM_ID, count(*)total_number_of_bids, REMARKS,TEAM_NAME
 from ipl_bidding_details ibgd
 join ipl_team it on ibgd.BID_TEAM=it.TEAM_ID
 group by TEAM_ID order by total_number_of_bids desc limit 1;
 
 #lowest no of bids:
 select it.TEAM_ID, count(*)total_number_of_bids, REMARKS,TEAM_NAME
 from ipl_bidding_details ibgd
 join ipl_team it on ibgd.BID_TEAM=it.TEAM_ID
 group by TEAM_ID order by total_number_of_bids limit 0,3;


/*3.	In a given stadium, what is the percentage of wins by a team which had won the toss?*/
#creating view for toss and match winner teams:
create view winner as
select a.match_id,tosswinner, matchwinner 
from (select *, case 
					when toss_winner = 1 then team_id1
					else team_id2 end as tosswinner 
                    from ipl_match)a 
join 
(select *, case 
					when match_winner = 1 then team_id1
					else team_id2 end as matchwinner
                    from ipl_match)b
on a.MATCH_ID=b.MATCH_ID;

#joining the view with stadium details:
create view stadium as
select w.match_id, ims.stadium_id, STADIUM_NAME , tosswinner, matchwinner
from winner w 
join ipl_match_schedule ims on w.MATCH_ID=ims.MATCH_ID
join ipl_stadium ist on ims.STADIUM_ID= ist.STADIUM_ID;

select a.match_id, a.stadium_id, a.stadium_name, a.tosswinner tosswinner_teamID, (c*100/c1)win_percentage
from (select *, count(*)c1 from stadium group by stadium_id)a
join
(select match_id, stadium_id, stadium_name, tosswinner, matchwinner,  count(*)c from stadium 
where tosswinner= matchwinner group by stadium_id order by stadium_name)b 
on a.stadium_id=b.stadium_id;


/*4.	What is the total no. of bids placed on the team that has won highest no. of matches?*/
select it.TEAM_ID, it.TEAM_NAME, total_wins, total_number_of_bids
from 
(select *, count(*)total_wins from winner group by matchwinner order by count(*) desc limit 1)a #team that won  highest no of matches
join ipl_team it on a.matchwinner= it.TEAM_ID 			#get the team id of most won team
join ( select it.TEAM_ID, count(*)total_number_of_bids, REMARKS,TEAM_NAME
from ipl_bidding_details ibgd
join ipl_team it on ibgd.BID_TEAM=it.TEAM_ID
group by TEAM_ID)total_bids_table						# this table is for calculating total_bids
on total_bids_table.TEAM_ID= it.TEAM_ID;				# join to get the team_id



/*5.	From the current team standings, if a bidder places a bid on which of the teams, 
there is a possibility of (s)he winning the highest no. of points – in simple words, 
identify the team which has the highest jump in its total points (in terms of percentage) 
from the previous year to current year.*/
select it.team_id, TEAM_NAME,TEAM_CITY,percentage  from (select 2017points.team_id, 
(2018points.total_points- 2017points.total_points)*100/(2017points.total_points)percentage
from 
(select * from ipl_team_standings where TOURNMT_ID =2017 group by  TEAM_ID)2017points
join
(select * from ipl_team_standings where TOURNMT_ID =2018 group by  TEAM_ID)2018points
on 2017points.TEAM_ID= 2018points.team_id
order by percentage desc limit 1)highestjumpedteam
join 
ipl_team it on highestjumpedteam.team_id= it.team_id;