mysql> describe bat.areadata;
+--------------+--------------+------+-----+---------+----------------+
| Field        | Type         | Null | Key | Default | Extra          |
+--------------+--------------+------+-----+---------+----------------+
| aindex       | int(11)      | NO   | PRI |         | auto_increment |
| xpos         | int(4)       | YES  | MUL |         |                |
| ypos         | int(4)       | YES  |     |         |                |
| conffile     | varchar(100) | NO   |     |         |                |
| areaname     | varchar(50)  | NO   |     |         |                |
| areatype     | varchar(8)   | NO   |     |         |                |
| hidden       | int(1)       | YES  |     |         |                |
| open         | int(1)       | YES  |     |         |                |
| areapath     | varchar(100) | YES  |     |         |                |
| creator      | varchar(20)  | YES  |     |         |                |
| mapchar      | char(1)      | YES  |     |         |                |
| maintainer   | varchar(20)  | YES  |     |         |                |
| orig_mapchar | char(1)      | YES  |     |         |                |
| continent    | varchar(64)  | YES  |     |         |                |
+--------------+--------------+------+-----+---------+----------------+
14 rows in set (0.00 sec)

