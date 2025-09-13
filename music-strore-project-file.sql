CREATE DATABASE IF NOT EXISTS music_store;

USE music_store;

-- Genre table
CREATE TABLE Genre (
genre_id INT PRIMARY KEY,
name VARCHAR(120)
);


-- MediaType table
CREATE TABLE MediaType (
    media_type_id INT PRIMARY KEY,
    name VARCHAR(120)
);

-- Employee table
CREATE TABLE Employee (
employee_id INT PRIMARY KEY,
last_name VARCHAR(120),
first_name VARCHAR(120),
title VARCHAR(120),
reports_to INT,
levels VARCHAR(255),
birthdate DATE,
hire_date DATE,
address VARCHAR(255),
city VARCHAR(100),
state VARCHAR(100),
country VARCHAR(100),
postal_code VARCHAR(20),
phone VARCHAR(50),
fax VARCHAR(50),
email VARCHAR(100)
);



-- Customer table
CREATE TABLE Customer (
customer_id INT PRIMARY KEY,
first_name VARCHAR(120),
last_name VARCHAR(120),
company VARCHAR(120),
address VARCHAR(255),
city VARCHAR(100),
state VARCHAR(100),
country VARCHAR(100),
postal_code VARCHAR(20),
phone VARCHAR(50),
fax VARCHAR(50),
email VARCHAR(100),
support_rep_id INT,
FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);


-- Artist table
CREATE TABLE Artist (
    artist_id INT PRIMARY KEY,
    name VARCHAR(120)
);


-- Album table
CREATE TABLE Album (
    album_id INT PRIMARY KEY,
    title VARCHAR(160),
    artist_id INT,
    FOREIGN KEY (artist_id)
        REFERENCES Artist (artist_id)
);


-- Track table
CREATE TABLE Track (
    track_id INT PRIMARY KEY,
    name VARCHAR(200),
    album_id INT,
    media_type_id INT,
    genre_id INT,
    composer VARCHAR(220),
    milliseconds INT,
    bytes INT,
    unit_price DECIMAL(10 , 2 ),
    FOREIGN KEY (album_id)
        REFERENCES Album (album_id),
    FOREIGN KEY (media_type_id)
        REFERENCES MediaType (media_type_id),
    FOREIGN KEY (genre_id)
        REFERENCES Genre (genre_id)
);


-- Invoice table
CREATE TABLE Invoice (
    invoice_id INT PRIMARY KEY,
    customer_id INT,
    invoice_date DATE,
    billing_address VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_country VARCHAR(100),
    billing_postal_code VARCHAR(20),
    total DECIMAL(10 , 2 ),
    FOREIGN KEY (customer_id)
        REFERENCES Customer (customer_id)
);

-- InvoiceLine table
CREATE TABLE InvoiceLine (
    invoice_line_id INT PRIMARY KEY,
    invoice_id INT,
    track_id INT,
    unit_price DECIMAL(10 , 2 ),
    quantity INT,
    FOREIGN KEY (invoice_id)
        REFERENCES Invoice (invoice_id),
    FOREIGN KEY (track_id)
        REFERENCES Track (track_id)
);


-- Playlist table
CREATE TABLE Playlist (
playlist_id INT PRIMARY KEY,
name VARCHAR(255)
);


-- PlaylistTrack table
CREATE TABLE PlaylistTrack (
playlist_id INT,
track_id INT,
PRIMARY KEY (playlist_id, track_id),
FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
FOREIGN KEY (track_id) REFERENCES Track(track_id)
);


SELECT * from Genre;

SELECT * from MediaType;

SELECT * from Employee;

SELECT * from Customer;

SELECT * from Artist;

SELECT * from Album;

SELECT * from Track;

SET GLOBAL local_infile = 1;

SELECT * FROM track ;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/track.csv'
INTO TABLE Track
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price);


SELECT COUNT(*) AS total_rows
FROM Track;

SELECT * from Invoice;

SELECT * from InvoiceLine;

SELECT * from Playlist;

SELECT * from PlaylistTrack;


-- Q1: Who is the senior most employee based on job title?
SELECT employee_id, first_name, last_name, title, levels
FROM Employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?
SELECT billing_country, COUNT(*) as invoice_count
FROM Invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

-- Q3: What are the top 3 values of total invoice?
SELECT total
FROM Invoice
ORDER BY total DESC
LIMIT 3;

-- Q4: Which city has the best customers?
SELECT billing_city, SUM(total) as total_revenue
FROM Invoice
GROUP BY billing_city
ORDER BY total_revenue DESC
LIMIT 1;

-- Q5: Who is the best customer?
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) as total_spent
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;

-- Q6: Return email, first name, last name & Genre of all Rock Music listeners
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
JOIN InvoiceLine il ON i.invoice_id = il.invoice_id
JOIN Track t ON il.track_id = t.track_id
JOIN Genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email ASC;


-- Q7: Top 10 rock artists by track count

SELECT ar.name AS artist_name, COUNT(t.track_id) AS rock_track_count
FROM Artist ar
JOIN Album al ON ar.artist_id = al.artist_id
JOIN Track t ON al.album_id = t.album_id
JOIN Genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY rock_track_count DESC
LIMIT 10;


-- Q8: Tracks longer than average song length
SELECT name, milliseconds
FROM Track
WHERE milliseconds > (
    SELECT AVG(milliseconds) 
    FROM Track
)
ORDER BY milliseconds DESC;

-- Q9: Amount spent by each customer on artists


SELECT c.first_name, c.last_name, ar.name AS artist_name, SUM(il.unit_price * il.quantity) AS total_spent
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
JOIN InvoiceLine il ON i.invoice_id = il.invoice_id
JOIN Track t ON il.track_id = t.track_id
JOIN Album al ON t.album_id = al.album_id
JOIN Artist ar ON al.artist_id = ar.artist_id
GROUP BY c.customer_id, ar.artist_id
ORDER BY total_spent DESC;



WITH customer_artist_spending AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        a.name AS artist_name,
        SUM(il.unit_price * il.quantity) AS total_spent
    FROM Customer c
    JOIN Invoice i ON c.customer_id = i.customer_id
    JOIN InvoiceLine il ON i.invoice_id = il.invoice_id
    JOIN Track t ON il.track_id = t.track_id
    JOIN Album al ON t.album_id = al.album_id
    JOIN Artist a ON al.artist_id = a.artist_id
    GROUP BY c.customer_id, c.first_name, c.last_name, a.artist_id, a.name
),
customer_totals AS (
    SELECT 
        customer_id,
        SUM(total_spent) AS customer_total
    FROM customer_artist_spending
    GROUP BY customer_id
)
SELECT 
    cas.customer_name,
    cas.artist_name,
    cas.total_spent,
    ct.customer_total
FROM customer_artist_spending cas
JOIN customer_totals ct ON cas.customer_id = ct.customer_id
ORDER BY ct.customer_total DESC, cas.customer_name, cas.total_spent DESC;




-- Q10: Most popular music genre for each country

WITH GenrePopularity AS (
    SELECT c.country, g.name AS genre_name, COUNT(il.invoice_line_id) AS purchases
    FROM Customer c
    JOIN Invoice i ON c.customer_id = i.customer_id
    JOIN InvoiceLine il ON i.invoice_id = il.invoice_id
    JOIN Track t ON il.track_id = t.track_id
    JOIN Genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.genre_id
)
SELECT country, genre_name, purchases
FROM GenrePopularity gp
WHERE purchases = (
    SELECT MAX(purchases)
    FROM GenrePopularity
    WHERE country = gp.country
)
ORDER BY country ASC, genre_name ASC;


-- Q11: Customer that spent most on music for each country
WITH customer_country_spending AS (
    SELECT i.billing_country, concat(c.first_name,' ', c.last_name) as customer_name,
           SUM(i.total) as total_spent,
           RANK() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) as spending_rank
    FROM Customer c
    JOIN Invoice i ON c.customer_id = i.customer_id
    GROUP BY i.billing_country, c.customer_id, c.first_name, c.last_name
)
SELECT billing_country, customer_name, total_spent
FROM customer_country_spending
WHERE spending_rank = 1
ORDER BY billing_country;





