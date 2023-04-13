-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT airplanes.aircraft_code,
       airplanes.model,
       seats.fare_conditions,
       count(seats.seat_no)
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
GROUP BY airplanes.model, airplanes.aircraft_code, seats.fare_conditions
ORDER BY airplanes.aircraft_code;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT airplanes.model,
       count(seats.seat_no)
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
GROUP BY airplanes.model
ORDER BY count(seats.seat_no) DESC
LIMIT 3;

-- 3. Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

SELECT airplanes.aircraft_code,
       airplanes.model,
       seats.seat_no
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
WHERE airplanes.model = 'Аэробус A321-200'
  AND NOT seats.fare_conditions = 'Economy'
ORDER BY seats.seat_no;

-- 4. Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

SELECT airports.airport_code,
       airports.airport_name,
       airports.city
FROM bookings.airports airports
WHERE airports.city
          IN (SELECT airports.city
              FROM airports
              GROUP BY airports.city
              HAVING count(airports.city) > 1);

-- 5. Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

SELECT flights.*
FROM bookings.flights_v flights
WHERE flights.departure_city = 'Екатеринбург'
  AND flights.arrival_city = 'Москва'
  AND bookings.now() < (flights.scheduled_departure - INTERVAL '40 minute')
ORDER BY flights.scheduled_departure
LIMIT 1;

-- 6. Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)

(SELECT tickets.ticket_no, tickets.amount AS cost
 FROM bookings.ticket_flights tickets
 WHERE tickets.amount = (SELECT min(bookings.ticket_flights.amount)
                         FROM bookings.ticket_flights)
 LIMIT 1)
UNION
(SELECT tickets.ticket_no, tickets.amount AS cost
 FROM bookings.ticket_flights tickets
 WHERE tickets.amount = (SELECT max(bookings.ticket_flights.amount)
                         FROM bookings.ticket_flights)
 LIMIT 1);

-- 7.1 Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints) .

CREATE DOMAIN email AS TEXT
    CHECK ( VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

CREATE DOMAIN phone AS TEXT
    CHECK ( VALUE ~ '^[+][0-9]{1,15}$');

CREATE TABLE IF NOT EXISTS customers
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY (INCREMENT 1 START 1 MINVALUE 1) PRIMARY KEY,
    first_name TEXT         NOT NULL CHECK (first_name != ''),
    last_name  TEXT         NOT NULL CHECK (last_name != ''),
    email      email,
    phone      phone UNIQUE NOT NULL
);

-- 7.2 Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + ограничения

CREATE TABLE IF NOT EXISTS orders
(
    id          BIGSERIAL,
    customer_id BIGINT,
    quantity    INTEGER,
    CONSTRAINT orders_id PRIMARY KEY (id),
    CONSTRAINT orders_quantity CHECK (quantity >= 0),
    FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 7.3 Написать 5 insert в эти таблицы

INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('John', 'Smith', 'noname@gmail.com', '+375290000001'),
       ('Adam', 'Lebowski', 'adam@gmail.com', '+375440000001'),
       ('Bob', 'Dow', 'noname@yandex.ru', '+375440007601'),
       ('Ёзеф', 'Полтавский', 'noname@outlook.com', '+375440075001'),
       ('Иван', 'Смирнов', 'noname@yandex.by', '+375330320001');

INSERT INTO orders(customer_id, quantity)
VALUES ((SELECT customers.id FROM customers WHERE customers.phone = '+375440000001'), 10),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375440000001'), 143),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375440007601'), 12),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375330320001'), 1000),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375290000001'), 1043);

-- 7.4 Удалить таблицы

DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS orders;
DROP DOMAIN IF EXISTS email;
DROP DOMAIN IF EXISTS phone;

-- 8. Написать свой кастомный запрос (rus + sql)

-- Находясь в Москве появилось неистовое желание полететь куда-нибудь,
-- добраться можно только до аэропортов Домодедово или Внуково,
-- потратить на билет готов от 5000 до 7500 рублей,
-- летим ближайшим рейсом (начало регистрации за 3 часа до отправления - конец за 35 минут до вылета)
-- варианты отсортировать по цене
-- (вывести номера рейсов, время отправления, аэропорт отправления, город прибытия и стоимость)

SELECT distinct flights.flight_no,
                flights.scheduled_departure,
                flights.departure_airport_name,
                flights.arrival_city,
                tickets.amount
FROM bookings.flights_v flights
         INNER JOIN ticket_flights tickets
                    ON flights.flight_id = tickets.flight_id
WHERE flights.departure_city = 'Москва'
  AND (flights.departure_airport_name = 'Домодедово' OR flights.departure_airport_name = 'Внуково')
  AND tickets.amount BETWEEN 5000 AND 7500
  AND bookings.now() BETWEEN
    (flights.scheduled_departure - INTERVAL '3 hour')
    AND
    (flights.scheduled_departure - INTERVAL '35 minute')
GROUP BY flights.flight_no,
         flights.scheduled_departure,
         flights.departure_airport_name,
         flights.arrival_city,
         tickets.amount
ORDER BY tickets.amount;

