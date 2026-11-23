/*
================================================================================
  Студент: Абрамов Данил Денисович
  Вариант: 3
  Заполните таблицы, созданные в рамках домашнего задания к практическому
  занятию 1, не менее чем 5-ю осмысленными записями. Данные возьмите из
  аналогичных систем в реальной жизни. Заполнение оформите в виде SQL-запросов.

  Запросы варианта 3:
  1. Выберите номера стеллажей, а также объём одного места и суммарный объём
     всех мест на каждом из них.
  2. Выберите номера помещений и суммарный объём всех мест всех стеллажей
     в каждом из них, оставив только те помещения, суммарный объём всех
     стеллажей которых больше 50 м3.

  Предметная область 
  Описание хранящихся на складе товаров. Включает в себя: описание помещений,
  описание стеллажей, описание клиентов, описание товаров, хранящихся на
  стеллажах. Описание помещения состоит из: названия, полезного объёма,
  температурных и влажностных условий. Описание стеллажа состоит из: номера,
  указания помещения, в котором стеллаж находится, количества мест для
  хранения в стеллаже, высоты, ширины и длины одного места, максимальной
  суммарной нагрузки. Описание клиента состоит из: названия юридического лица
  и банковских реквизитов в виде большого текста. Описание товара, хранящегося
  на стеллажах, состоит из: высоты, ширины, длины, веса, даты поступления,
  номера договора, указания, от какого клиента поступил, даты окончания
  договора, температурных и влажностных условий хранения, указания стеллажа,
  и позиции размещения на нём, представляемой в виде целого номера.
  На одном стеллаже могут храниться товары только одного клиента.

  Единицы измерения: объём - м3; размеры - см; вес и нагрузка - кг;
  температура - °C; влажность - %.
================================================================================
*/



DROP TABLE IF EXISTS item;
DROP TABLE IF EXISTS rack;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS room;


CREATE TABLE room (
    room_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR(100)  NOT NULL,
    useful_volume    NUMERIC(10,2) NOT NULL,
    temperature_min  NUMERIC(4,1)  NOT NULL,
    temperature_max  NUMERIC(4,1)  NOT NULL,
    humidity_min     NUMERIC(4,1)  NOT NULL DEFAULT 0,
    humidity_max     NUMERIC(4,1)  NOT NULL DEFAULT 100,

    CONSTRAINT uq_room_name          UNIQUE (name),
    CONSTRAINT ck_room_name          CHECK (btrim(name) <> ''),
    CONSTRAINT ck_room_volume        CHECK (useful_volume > 0),
    CONSTRAINT ck_room_temperature   CHECK (temperature_min BETWEEN -60 AND 60
                                        AND temperature_max BETWEEN -60 AND 60
                                        AND temperature_min <= temperature_max),
    CONSTRAINT ck_room_humidity      CHECK (humidity_min BETWEEN 0 AND 100
                                        AND humidity_max BETWEEN 0 AND 100
                                        AND humidity_min <= humidity_max)
);


CREATE TABLE client (
    client_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    legal_name    VARCHAR(255) NOT NULL,
    bank_details  TEXT         NOT NULL,

    CONSTRAINT uq_client_legal_name   UNIQUE (legal_name),
    CONSTRAINT ck_client_legal_name   CHECK (btrim(legal_name) <> ''),
    CONSTRAINT ck_client_bank_details CHECK (btrim(bank_details) <> '')
);


CREATE TABLE rack (
    rack_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rack_number    INTEGER       NOT NULL,
    room_id        INTEGER       NOT NULL,
    client_id      INTEGER,
    slots_count    INTEGER       NOT NULL,
    slot_height    NUMERIC(7,2)  NOT NULL,
    slot_width     NUMERIC(7,2)  NOT NULL,
    slot_length    NUMERIC(7,2)  NOT NULL,
    max_load       NUMERIC(10,2) NOT NULL,

    CONSTRAINT fk_rack_room   FOREIGN KEY (room_id)
        REFERENCES room (room_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_rack_client FOREIGN KEY (client_id)
        REFERENCES client (client_id) ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT uq_rack_number_in_room UNIQUE (room_id, rack_number),
    CONSTRAINT uq_rack_client         UNIQUE (rack_id, client_id),

    CONSTRAINT ck_rack_number      CHECK (rack_number > 0),
    CONSTRAINT ck_rack_slots       CHECK (slots_count > 0),
    CONSTRAINT ck_rack_slot_size   CHECK (slot_height > 0
                                      AND slot_width  > 0
                                      AND slot_length > 0),
    CONSTRAINT ck_rack_max_load    CHECK (max_load > 0)
);


CREATE TABLE item (
    item_id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    height              NUMERIC(7,2)  NOT NULL,
    width               NUMERIC(7,2)  NOT NULL,
    length              NUMERIC(7,2)  NOT NULL,
    weight              NUMERIC(10,3) NOT NULL,
    arrival_date        DATE          NOT NULL DEFAULT CURRENT_DATE,
    contract_number     VARCHAR(50)   NOT NULL,
    client_id           INTEGER       NOT NULL,
    contract_end_date   DATE          NOT NULL,
    temperature_min     NUMERIC(4,1)  NOT NULL,
    temperature_max     NUMERIC(4,1)  NOT NULL,
    humidity_min        NUMERIC(4,1)  NOT NULL DEFAULT 0,
    humidity_max        NUMERIC(4,1)  NOT NULL DEFAULT 100,
    rack_id             INTEGER       NOT NULL,
    position_number     INTEGER       NOT NULL,

    CONSTRAINT fk_item_client FOREIGN KEY (client_id)
        REFERENCES client (client_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_item_rack_client FOREIGN KEY (rack_id, client_id)
        REFERENCES rack (rack_id, client_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_item_rack_position UNIQUE (rack_id, position_number),

    CONSTRAINT ck_item_size        CHECK (height > 0 AND width > 0 AND length > 0),
    CONSTRAINT ck_item_weight      CHECK (weight > 0),
    CONSTRAINT ck_item_contract_no CHECK (btrim(contract_number) <> ''),
    CONSTRAINT ck_item_dates       CHECK (contract_end_date >= arrival_date),
    CONSTRAINT ck_item_temperature CHECK (temperature_min BETWEEN -60 AND 60
                                      AND temperature_max BETWEEN -60 AND 60
                                      AND temperature_min <= temperature_max),
    CONSTRAINT ck_item_humidity    CHECK (humidity_min BETWEEN 0 AND 100
                                      AND humidity_max BETWEEN 0 AND 100
                                      AND humidity_min <= humidity_max),
    CONSTRAINT ck_item_position    CHECK (position_number > 0)
);


CREATE INDEX ix_rack_room   ON rack (room_id);
CREATE INDEX ix_rack_client ON rack (client_id);
CREATE INDEX ix_item_client ON item (client_id);


INSERT INTO room (name, useful_volume, temperature_min, temperature_max, humidity_min, humidity_max) VALUES
    ('Холодильная камера', 800,   2,   4, 80, 90),
    ('Морозильная камера', 600, -20, -10, 85, 95),
    ('Сухой склад', 2500,  15,  25, 40, 60),
    ('Склад химии', 400,  10,  20, 30, 50),
    ('Склад электроники', 1200,  18,  22, 30, 45);

INSERT INTO client (legal_name, bank_details) VALUES
    ('ООО «Молочная компания»',  'р/с 1234'),
    ('ООО «Морепродукты»', 'р/с 2345'),
    ('ООО «Стройтельная»',  'р/с 3456'),
    ('АО «ХимПром»', 'р/с 4567'),
    ('ООО «ТехноМаркет»', 'р/с 5678');

INSERT INTO rack (rack_number, room_id, client_id, slots_count, slot_height, slot_width, slot_length, max_load) VALUES
    (1, 1, 1, 30, 100, 100, 100, 10000),
    (2, 1, 1, 30, 100, 100, 100, 10000),
    (1, 2, 2, 20, 100, 100, 100, 10000),
    (1, 3, 3, 40, 150, 100, 100, 20000),
    (1, 4, 4, 10, 100, 100,  50,  5000),
    (1, 5, 5, 20,  50, 100, 100,  3000);

INSERT INTO item (height, width, length, weight, arrival_date, contract_number, client_id,
                  contract_end_date, temperature_min, temperature_max, humidity_min, humidity_max,
                  rack_id, position_number) VALUES
    (100, 100, 100, 500, '2026-11-01', 'Д-001', 1, '2027-11-01', 2, 4, 80, 90, 1, 1),
    ( 80, 100, 100, 400, '2026-11-01', 'Д-001', 1, '2027-11-01', 2, 4, 80, 90, 2, 1),
    (100, 100, 100, 600, '2026-11-05', 'Д-002', 2, '2027-05-05', -20, -10, 85, 95, 3, 1),
    (150, 100, 100, 800, '2026-11-10', 'Д-003', 3, '2027-11-10',  15,  25, 40, 60, 4, 1),
    ( 50, 100,  50, 200, '2026-11-15', 'Д-004', 4, '2027-05-15',  10,  20, 30, 50, 5, 1),
    ( 50, 100, 100, 100, '2026-11-20', 'Д-005', 5, '2027-11-20',  18,  22, 30, 45, 6, 1);


SELECT
    r.rack_number                                                    AS "Номер стеллажа",
    rm.name                                                          AS "Помещение",
    ROUND(r.slot_height * r.slot_width * r.slot_length / 1000000, 2) AS "Объём места, м3",
    ROUND(r.slot_height * r.slot_width * r.slot_length * r.slots_count / 1000000, 2) AS "Объём всех мест, м3"
FROM rack r
JOIN room rm ON rm.room_id = r.room_id
ORDER BY rm.room_id, r.rack_number;

SELECT
    rm.room_id                                                       AS "Номер помещения",
    rm.name                                                          AS "Помещение",
    ROUND(SUM(r.slot_height * r.slot_width * r.slot_length * r.slots_count) / 1000000, 2) AS "Объём всех мест, м3"
FROM room rm
JOIN rack r ON r.room_id = rm.room_id
GROUP BY rm.room_id, rm.name
HAVING SUM(r.slot_height * r.slot_width * r.slot_length * r.slots_count) / 1000000 > 50
ORDER BY rm.room_id;