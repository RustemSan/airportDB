-- odeberu pokud existuje funkce na oodebrání tabulek a sekvencí
DROP FUNCTION IF EXISTS remove_all();

-- vytvořím funkci která odebere tabulky a sekvence
-- chcete také umět psát PLSQL? Zapište si předmět BI-SQL ;-)
CREATE or replace FUNCTION remove_all() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    FOR rec IN SELECT
            'DROP SEQUENCE ' || quote_ident(n.nspname) || '.'
                || quote_ident(c.relname) || ' CASCADE;' AS name
        FROM
            pg_catalog.pg_class AS c
        LEFT JOIN
            pg_catalog.pg_namespace AS n
        ON
            n.oid = c.relnamespace
        WHERE
            relkind = 'S' AND
            n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
            pg_catalog.pg_table_is_visible(c.oid)
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    FOR rec IN SELECT
            'DROP TABLE ' || quote_ident(n.nspname) || '.'
                || quote_ident(c.relname) || ' CASCADE;' AS name
        FROM
            pg_catalog.pg_class AS c
        LEFT JOIN
            pg_catalog.pg_namespace AS n
        ON
            n.oid = c.relnamespace WHERE relkind = 'r' AND
            n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
            pg_catalog.pg_table_is_visible(c.oid)
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- zavolám funkci co odebere tabulky a sekvence - Mohl bych dropnout celé schéma a znovu jej vytvořit, použíjeme však PLSQL
select remove_all();

-- Remove conflicting tables
--DROP TABLE IF EXISTS aviacompany CASCADE;
--DROP TABLE IF EXISTS baggage CASCADE;
--DROP TABLE IF EXISTS employee CASCADE;
--DROP TABLE IF EXISTS flight CASCADE;
--DROP TABLE IF EXISTS passanger CASCADE;
--DROP TABLE IF EXISTS pilot CASCADE;
--DROP TABLE IF EXISTS pilot_flight CASCADE;
--DROP TABLE IF EXISTS plane CASCADE;
--DROP TABLE IF EXISTS stewardess CASCADE;
--DROP TABLE IF EXISTS stewardess_flight CASCADE;
--DROP TABLE IF EXISTS ticket CASCADE;
-- End of removing

CREATE TABLE aviacompany (
    id_company SERIAL NOT NULL,
    company_name VARCHAR(256) NOT NULL,
    headquarters VARCHAR(256) NOT NULL,
    founding_date VARCHAR(256) NOT NULL,
    fleet_size Integer NOT NULL
);
ALTER TABLE aviacompany ADD CONSTRAINT pk_aviacompany PRIMARY KEY (id_company);

CREATE TABLE baggage (
    id_baggage SERIAL NOT NULL,
    id_ticket INTEGER NOT NULL,
    weight integer NOT NULL,
    height integer NOT NULL,
    status VARCHAR(256) NOT NULL,
    luggage_type VARCHAR(256) NOT NULL
);
ALTER TABLE baggage ADD CONSTRAINT pk_baggage PRIMARY KEY (id_baggage);

CREATE TABLE employee (
    id_employee SERIAL NOT NULL,
    id_company INTEGER,
    full_name VARCHAR(256) NOT NULL,
    position VARCHAR(256) NOT NULL,
    hire_date VARCHAR(256) NOT NULL,
    salary INTEGER NOT NULL
);
ALTER TABLE employee ADD CONSTRAINT pk_employee PRIMARY KEY (id_employee);

CREATE TABLE flight (
    id_flight SERIAL NOT NULL,
    id_plane INTEGER NOT NULL,
    departure_time VARCHAR(256) NOT NULL,
    arrival_time VARCHAR(256) NOT NULL,
    duration INTEGER NOT NULL,
    status VARCHAR(256) NOT NULL
);
ALTER TABLE flight ADD CONSTRAINT pk_flight PRIMARY KEY (id_flight);

CREATE TABLE passenger (
    id_passenger SERIAL NOT NULL,
    city VARCHAR(256) NOT NULL,
    full_name VARCHAR(256) NOT NULL,
    date_of_birth VARCHAR(256) NOT NULL,
    gender VARCHAR(256) NOT NULL
);
ALTER TABLE passenger ADD CONSTRAINT pk_passenger PRIMARY KEY (id_passenger);

CREATE TABLE pilot (
    id_employee INTEGER NOT NULL,
    license_number integer NOT NULL,
    qualification VARCHAR(256) NOT NULL,
    flight_hours INTEGER NOT NULL
);
ALTER TABLE pilot ADD CONSTRAINT pk_pilot PRIMARY KEY (id_employee);

CREATE TABLE pilot_flight (
    id_employee INTEGER NOT NULL,
    id_flight INTEGER NOT NULL,
    position VARCHAR(256) NOT NULL
);
ALTER TABLE pilot_flight ADD CONSTRAINT pk_pilot_flight PRIMARY KEY (id_employee, id_flight);

CREATE TABLE plane (
    id_plane SERIAL NOT NULL,
    id_company INTEGER NOT NULL,
    model VARCHAR(256) NOT NULL,
    capacity INTEGER NOT NULL,
    year_of_manufacture INTEGER NOT NULL
);
ALTER TABLE plane ADD CONSTRAINT pk_plane PRIMARY KEY (id_plane);

CREATE TABLE stewardess (
    id_employee INTEGER NOT NULL,
    qualification VARCHAR(256) NOT NULL
);
ALTER TABLE stewardess ADD CONSTRAINT pk_stewardess PRIMARY KEY (id_employee);

CREATE TABLE stewardess_flight (
    id_employee INTEGER NOT NULL,
    id_flight INTEGER NOT NULL,
    feedback Integer NOT NULL,
    service_date VARCHAR(256) NOT NULL
);
ALTER TABLE stewardess_flight ADD CONSTRAINT pk_stewardess_flight PRIMARY KEY (id_employee, id_flight);

CREATE TABLE ticket (
    id_ticket SERIAL NOT NULL,
    id_passenger INTEGER NOT NULL,
    id_flight INTEGER,
    seat_number VARCHAR(256) NOT NULL,
    class VARCHAR(256) NOT NULL,
    price integer NOT NULL
);
ALTER TABLE ticket ADD CONSTRAINT pk_ticket PRIMARY KEY (id_ticket);

ALTER TABLE baggage ADD CONSTRAINT fk_baggage_ticket FOREIGN KEY (id_ticket) REFERENCES ticket (id_ticket) ON DELETE CASCADE;

ALTER TABLE employee ADD CONSTRAINT fk_employee_aviacompany FOREIGN KEY (id_company) REFERENCES aviacompany (id_company) ON DELETE CASCADE;

ALTER TABLE flight ADD CONSTRAINT fk_flight_plane FOREIGN KEY (id_plane) REFERENCES plane (id_plane) ON DELETE CASCADE;

ALTER TABLE pilot ADD CONSTRAINT fk_pilot_employee FOREIGN KEY (id_employee) REFERENCES employee (id_employee) ON DELETE CASCADE;

ALTER TABLE pilot_flight ADD CONSTRAINT fk_pilot_flight_pilot FOREIGN KEY (id_employee) REFERENCES pilot (id_employee) ON DELETE CASCADE;
ALTER TABLE pilot_flight ADD CONSTRAINT fk_pilot_flight_flight FOREIGN KEY (id_flight) REFERENCES flight (id_flight) ON DELETE CASCADE;

ALTER TABLE plane ADD CONSTRAINT fk_plane_aviacompany FOREIGN KEY (id_company) REFERENCES aviacompany (id_company) ON DELETE CASCADE;

ALTER TABLE stewardess ADD CONSTRAINT fk_stewardess_employee FOREIGN KEY (id_employee) REFERENCES employee (id_employee) ON DELETE CASCADE;

ALTER TABLE stewardess_flight ADD CONSTRAINT fk_stewardess_flight_stewardess FOREIGN KEY (id_employee) REFERENCES stewardess (id_employee) ON DELETE CASCADE;
ALTER TABLE stewardess_flight ADD CONSTRAINT fk_stewardess_flight_flight FOREIGN KEY (id_flight) REFERENCES flight (id_flight) ON DELETE CASCADE;

ALTER TABLE ticket ADD CONSTRAINT fk_ticket_passenger FOREIGN KEY (id_passenger) REFERENCES passenger (id_passenger) ON DELETE CASCADE;
ALTER TABLE ticket ADD CONSTRAINT fk_ticket_flight FOREIGN KEY (id_flight) REFERENCES flight (id_flight) ON DELETE CASCADE;

