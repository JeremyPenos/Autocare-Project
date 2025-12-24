-- Client
create table client 
(client_id varchar(4) PRIMARY KEY,
fname varchar(25),
lname varchar(25),
str_addr varchar(50),
city varchar(50),
state varchar(2),
zipcode varchar(10),
spouse varchar(25),
add_driver1 varchar(25),
add_driver2 varchar(25),
home_phone varchar(10),
cell_phone varchar(10));


-- Vehicle
create table vehicle
(VIN varchar(17) PRIMARY KEY,
year smallint,
make varchar(25),
model varchar(25),
color varchar(25),
client_id varchar(4),
CONSTRAINT fk_vehicle FOREIGN KEY (client_id) REFERENCES client(client_id),
CONSTRAINT VIN_length CHECK (len(VIN) = 17));


-- Location
create table location 
(loc_id varchar(4) PRIMARY KEY,
loc_name varchar(25),
loc_address varchar(50),
loc_city varchar(50),
loc_st varchar(50),
loc_phone varchar(10));


-- Department
create table dept
(dept_id varchar(4) PRIMARY KEY,
dept_name varchar(25),
dept_budget numeric(8,2),
building varchar(2),
floor varchar(2),
location_id varchar(4),
CONSTRAINT fk_dept FOREIGN KEY (location_id) REFERENCES location(loc_id));


-- Staff
create table staff 
(staff_id varchar(4) PRIMARY KEY,
fname varchar(25),
lname varchar(25),
dept_id varchar(4),
CONSTRAINT fk_staff FOREIGN KEY (dept_id) REFERENCES dept(dept_id));


-- Certification
create table certification
(cert_id varchar(4) PRIMARY KEY,
cert_desc varchar(100),
cert_body varchar(50),
cert_date date,
staff_id varchar(4),
CONSTRAINT fk_cert FOREIGN KEY (staff_id) REFERENCES staff(staff_id));


-- Vehicle care plan
create table vehicle_care_plan
(plan_id varchar(10) PRIMARY KEY,
plan_start datetime DEFAULT (GETDATE()),
plan_end datetime,
severity_level char,
comments varchar(100),
staff_id varchar(4),
dept_id varchar(4),
VIN varchar(17),
CONSTRAINT fk_vcp_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
CONSTRAINT fk_vcp_dept FOREIGN KEY (dept_id) REFERENCES dept(dept_id),
CONSTRAINT fk_vcp_vin FOREIGN KEY (VIN) REFERENCES vehicle(VIN),
CONSTRAINT completedate_after_creationdate CHECK (plan_end>plan_start));


-- Recall
create table recall
(recall_id varchar(4) PRIMARY KEY,
recall_desc varchar(100),
VIN varchar(17),
CONSTRAINT fk_recall FOREIGN KEY (VIN) REFERENCES vehicle(VIN));


-- Review
create table review
(review_id varchar(10) PRIMARY KEY,
ques_1 numeric(1),
ques_2 numeric(1),
ques_3 numeric(1),
ques_4 numeric(1),
ques_5 numeric(1),
comments varchar(100),
plan_id varchar(10),
CONSTRAINT fk_review FOREIGN KEY (plan_id) REFERENCES vehicle_care_plan(plan_id));


-- Part
create table part
(part_id varchar(4) PRIMARY KEY,
part_name varchar(50),
part_desc varchar(100),
part_category varchar(25),
part_cost_retail money,
part_cost_wholesale money);


-- Plan part
create table plan_part
(plan_id varchar(10),
part_id varchar(4), 
PRIMARY KEY (plan_id, part_id),
CONSTRAINT fk_vhp_plan_part FOREIGN KEY (plan_id) REFERENCES vehicle_care_plan(plan_id),
CONSTRAINT fk_plan_part FOREIGN KEY (part_id) REFERENCES part(part_id));


-- Bill
create table bill
(bill_id varchar(10) PRIMARY KEY,
bill_date datetime,
amt_due money,
paid bit,
client_id varchar(4),
CONSTRAINT fk_bill FOREIGN KEY (client_id) REFERENCES client(client_id));


-- Invoice
create table invoice
(inv_id varchar(10) PRIMARY KEY,
inv_date datetime,
hrs_worked smallint,
hourly_rate money,
plan_id varchar(10),
bill_id varchar(10),
dept_id varchar(4),
CONSTRAINT fk_vhp_invoice FOREIGN KEY (plan_id) REFERENCES vehicle_care_plan(plan_id),
CONSTRAINT fk_bill_invoice FOREIGN KEY (bill_id) REFERENCES bill(bill_id),
CONSTRAINT fk_dept_invoice FOREIGN KEY (dept_id) REFERENCES dept(dept_id));


-- Vendor
create table vendor
(ven_id varchar(4) PRIMARY KEY,
ven_name varchar(50),
ven_phone varchar(10),
ven_contact varchar(25));

-- Vendor part
create table vendor_part
(ven_id varchar(4),
part_id varchar(4),
date_ordered date,
qty_ordered numeric(3),
date_received date,
qty_received numeric(3),
qty_damaged numeric(3),
PRIMARY KEY (ven_id, part_id),
CONSTRAINT fk_vendor_vendor FOREIGN KEY (ven_id) REFERENCES vendor(ven_id),
CONSTRAINT FK_vendor_part FOREIGN KEY (part_id) REFERENCES part(part_id),
CONSTRAINT recieved_after_order CHECK (date_received > date_ordered));