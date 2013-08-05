mysql> describe bat.chan_sales;
+---------+--------------+------+-----+-------------------+-------+
| Field   | Type         | Null | Key | Default           | Extra |
+---------+--------------+------+-----+-------------------+-------+
| msgtime | timestamp    | YES  |     | CURRENT_TIMESTAMP |       |
| channel | varchar(255) | YES  |     | NULL              |       |
| author  | varchar(255) | YES  |     | NULL              |       |
| message | mediumtext   | YES  |     | NULL              |       |
+---------+--------------+------+-----+-------------------+-------+
