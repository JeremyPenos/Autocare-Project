-- Staff Members that scored less than 20 points based on feedback from client reviews

SELECT 
    s.staff_id as [Staff ID],
    s.fname [First Name],
    s.lname [Last Name],
    SUM(r.ques_1 + r.ques_2 + r.ques_3 + r.ques_4 + r.ques_5) AS [Total Score]
FROM Staff AS s
JOIN vehicle_care_plan AS v
    ON v.staff_id = s.staff_id
JOIN review AS r
	ON r.plan_id = v.plan_id
GROUP BY 
    s.staff_id,
    s.fname,
    s.lname
HAVING 
    SUM(r.ques_1 + r.ques_2 + r.ques_3 + r.ques_4 + r.ques_5) < 20


-- Parts Ordered in Current Month

SELECT v.ven_name as [Vendor Name], 
	   p.part_name as [Part Name], 
	   vp.qty_ordered as [Quantity Ordered]
FROM vendor as v
INNER JOIN vendor_part as vp
	ON v.ven_id = vp.ven_id
INNER JOIN part as p
	ON p.part_id = vp.part_id
WHERE 
    MONTH(vp.date_ordered) = MONTH(GETDATE())


-- Client Info matching Recall Description

SELECT c.fname as [First Name], 
	   c.lname as [Last Name], 
	   c.home_phone as [Home Phone], 
	   c.cell_phone as [Cell Phone], 
	   r.recall_desc as [Recall Description]
FROM client c
INNER JOIN vehicle v ON c.client_id = v.client_id
INNER JOIN recall r ON r.VIN = v.VIN
ORDER BY lname, fname



-- Stored Procedure

IF EXISTS (SELECT name FROM sysobjects where name = 'client_report_JBNS' AND TYPE = 'P')
DROP PROCEDURE client_report_JBNS
GO

CREATE PROCEDURE client_report_JBNS
@clientID varchar(4) = NULL

AS

DECLARE

@client_fname varchar(40),
@client_lname varchar(40),
@client_hphone varchar(15),
@client_cell varchar(15)

BEGIN



--- Header of Report ---

SELECT @client_fname = fname, 
	   @client_lname = lname,
	   @client_hphone = home_phone,
	   @client_cell = cell_phone
FROM client
WHERE client_id = @clientID

SET @client_hphone =
	'(' + SUBSTRING(@client_hphone, 1, 3) + ') '
	+ SUBSTRING(@client_hphone, 4, 3) + '-'
	+ SUBSTRING(@client_hphone, 7, 4);

SET @client_cell = 
	'(' + SUBSTRING(@client_cell, 1, 3) + ') '
	+ SUBSTRING(@client_cell, 4, 3) + '-' 
	+ SUBSTRING(@client_cell, 7, 4);


print '**********************************'
print 'Client ID: ' + @clientID
print 'Client Name: ' + @client_fname + ' ' + @client_lname
print 'Home Phone: ' + @client_hphone
print 'Cell Phone: ' + @client_cell
print 'Report Date: ' + DATENAME(month, GETDATE()) + ' ' + CONVERT(varchar, DAY(GETDATE())) + ', ' + CONVERT(varchar, YEAR(GETDATE()))
print '**********************************'
print ' '
print ' '
print ' '


--- Vehicle Care Plan ---

print '**********************************'
print 'Vehicle Care Plan(s)'
print '**********************************'
print'VIN						Start Date						End Date						Severity Level'



DECLARE vcp_cursor CURSOR FOR

SELECT vcp.VIN,
	   vcp.plan_start,
	   vcp.plan_end,
	   vcp.severity_level
FROM vehicle_care_plan vcp
INNER JOIN vehicle v ON vcp.VIN = v.VIN
WHERE v.client_id = @clientID
ORDER BY vcp.plan_start

DECLARE
@vin varchar(17),
@start_date DATE,
@end_date DATE,
@sev_lvl varchar(1)

OPEN vcp_cursor

	IF @@CURSOR_ROWS = 0
		BEGIN
			RAISERROR('No Vehicle Care Plan Found', 10, 1)
			RETURN
		END

	FETCH FROM vcp_cursor
	INTO @vin, @start_date, @end_date, @sev_lvl

	WHILE @@FETCH_STATUS = 0
	BEGIN
		print @vin + '		' + CONVERT(varchar, @start_date, 101) + '						'
		+ CONVERT(varchar, @end_date, 101) + '						' + @sev_lvl

		FETCH NEXT FROM vcp_cursor
		INTO @vin, @start_date, @end_date, @sev_lvl

	END

CLOSE vcp_cursor
DEALLOCATE vcp_cursor

print ' '
print ' '
print ' '


--- Invoice ---

print '**********************************'
print 'Invoices(s)'
print '**********************************'
print 'Date				VIN							Hours Worked			Total Cost Parts			Total Cost Labor			Total Cost'



DECLARE inv_cursor CURSOR FOR

SELECT i.inv_date,
	   vcp.VIN,
	   i.hrs_worked,
	   ISNULL(SUM(p.part_cost_retail), 0) as [part_cost],
	   (i.hrs_worked * i.hourly_rate) as [labor_cost],
	   ISNULL(SUM(p.part_cost_retail), 0) + (i.hrs_worked * i.hourly_rate) as [total cost]
FROM invoice i

INNER JOIN vehicle_care_plan vcp	ON i.plan_id = vcp.plan_id
INNER JOIN bill b					ON i.bill_id = b.bill_id
INNER JOIN plan_part pp				ON i.plan_id = pp.plan_id
INNER JOIN part p					ON pp.part_id = p.part_id

WHERE b.client_id = @clientID
GROUP BY i.inv_date,
		 vcp.VIN,
		 i.hrs_worked,
		 i.hourly_rate
ORDER BY i.inv_date

DECLARE
@i_date DATE,
@i_vin varchar(17),
@hrs_worked smallint,
@cost_parts numeric(5,2),
@cost_labor numeric(5,2),
@total_cost numeric(5,2)

OPEN inv_cursor

	IF @@CURSOR_ROWS = 0
		BEGIN
			RAISERROR('No Invoice Found', 10, 1)
			RETURN
		END

	FETCH FROM inv_cursor
	INTO @i_date, @i_vin, @hrs_worked, @cost_parts, @cost_labor, @total_cost
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		print CONVERT(varchar, @i_date, 101) + '			' + @i_vin + '			'
			  + CONVERT(varchar, @hrs_worked) + '						' + FORMAT(@cost_parts, 'c')
			  + '						' + FORMAT(@cost_labor, 'c') + '						' 
			  + FORMAT(@total_cost, 'c')

		FETCH NEXT FROM inv_cursor
		INTO @i_date, @i_vin, @hrs_worked, @cost_parts, @cost_labor, @total_cost
	END

CLOSE inv_cursor
DEALLOCATE inv_cursor

print ' '
print ' '
print ' '

--- Bill ---

print '**********************************'
print 'Bill'
print '**********************************'
print 'Date				Amount Due				Paid?'


DECLARE bill_cursor CURSOR FOR

SELECT bill_date,
	   amt_due,
	   paid
FROM bill
WHERE client_id = @clientID
ORDER BY bill_date

DECLARE
@b_date DATE,
@amt_due numeric(5,2),
@paid bit

OPEN bill_cursor

	IF @@CURSOR_ROWS = 0
		BEGIN
			RAISERROR('No Bill Found', 10, 1)
			RETURN
		END

	FETCH FROM bill_cursor
	INTO @b_date, @amt_due, @paid
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @paid = 1
			print CONVERT(varchar, @b_date, 101) + '			' + FORMAT(@amt_due, 'c') + '					' + 'Y'
		ELSE
			print CONVERT(varchar, @b_date, 101) + '			' + FORMAT(@amt_due, 'c') + '					' + 'N'

		FETCH NEXT FROM bill_cursor
		INTO @b_date, @amt_due, @paid
	END

CLOSE bill_cursor
DEALLOCATE bill_cursor

END
GO

EXEC client_report_JBNS C001



-- Trigger (delete a client record)

/*
ALTER TABLE client ADD record_status varchar(20)

CREATE TABLE log_table(
client_id		varchar(4),
fname			varchar(50),
lname			varchar(50),
[system_user]	varchar(50),
[date]			datetime
)
*/

/* Setting record_status upon instert to read 'Active'

ALTER TABLE client
ADD CONSTRAINT DF_client_status
DEFAULT('Active') FOR record_status

Setting pre-existing records to 'Active'

UPDATE client
SET record_status = 'Active'
WHERE record_status IS NULL
*/

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'logical_delete' AND type = 'TR')  
DROP TRIGGER logical_delete;
GO

CREATE TRIGGER logical_delete
ON Client INSTEAD OF DELETE

AS

DECLARE
@clientID varchar(4),
@first_name varchar(50),
@last_name varchar(50)

BEGIN

	SELECT @clientID = client_id FROM DELETED
	
	UPDATE client
	SET record_status = 'Inactive'
	WHERE client_id = @clientID

	SELECT @first_name = fname,
		   @last_name = lname
	FROM DELETED
	WHERE client_id = @clientID

	INSERT INTO log_table
	VALUES(@clientID, @first_name, @last_name, SYSTEM_USER, GETDATE())

END
GO

SELECT * FROM client

SET implicit_transactions ON
GO

INSERT INTO client(client_id,fname,lname, str_addr, city, [state], zipcode, cell_phone)
Values ('C011','Jeremy', 'Penos', '1234 Baylor Drive', 'Waco', 'TX', 75034, '1234567890')

SELECT * 
FROM client 
WHERE client_id = 'C011'

DELETE FROM client
WHERE client_id = 'C011'

SELECT * 
FROM client
WHERE client_id = 'C011'

SELECT * FROM log_table

Rollback
SET implicit_transactions OFF
GO